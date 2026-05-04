/* ════════════════════════════════════════════════════════════════
   J0K3R-whitelist_spawnselector - UI SCRIPT
   Author: J0K3R-SCRIPTS

   Vanilla JS - no external framework dependencies.
   Receives SendNUIMessage from the client and posts callbacks back.
   ════════════════════════════════════════════════════════════════ */

(() => {

const $  = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

const state = {
    config: null,
    spawnSelected: null,
    quiz: {
        questions: [],
        currentIdx: 0,
        answers: {},          // [questionIndex] = answerIndex (1-based)
        timeLeft: 0,
        timerHandle: null,
    },
};

/* ─── HELPERS ──────────────────────────────────────────────── */

function sendCallback(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(data),
    }).then(r => r.json()).catch(() => ({ ok: false }));
}

function applyDesign(design) {
    const r = document.documentElement.style;
    r.setProperty("--primary",     design.PrimaryColor);
    r.setProperty("--secondary",   design.SecondaryColor);
    r.setProperty("--success",     design.SuccessColor);
    r.setProperty("--bg",          design.BackgroundColor);
    r.setProperty("--text",        design.TextColor);
    r.setProperty("--opacity",     design.Opacity);
    r.setProperty("--border",      design.BorderColor);
    r.setProperty("--font-header", `"${design.FontHeader}", serif`);
    r.setProperty("--font-body",   `"${design.FontBody}", serif`);
    r.setProperty("--bg-image",    `url("${design.BackgroundImage}")`);
}

function applyLocale(locale) {
    $$("[data-i18n]").forEach(el => {
        const key = el.getAttribute("data-i18n");
        if (locale[key]) el.textContent = locale[key];
    });
}

function showStage(stageName) {
    $$(".stage").forEach(s => {
        s.style.display = (s.getAttribute("data-stage") === stageName) ? "" : "none";
    });
}

function fmtTime(seconds) {
    const m = Math.floor(seconds / 60).toString().padStart(2, "0");
    const s = (seconds % 60).toString().padStart(2, "0");
    return `${m}:${s}`;
}

/* ─── STAGE: SPAWN ─────────────────────────────────────────── */

function buildSpawnCards() {
    const grid = $("#spawn-cards");
    grid.innerHTML = "";

    const spawns = state.config.Spawns || {};
    const locale = state.config.Locale  || {};

    for (const key of Object.keys(spawns)) {
        const data = spawns[key];

        const card = document.createElement("div");
        card.className = "spawn-card";
        card.dataset.spawn = key;

        // Image
        const img = document.createElement("div");
        img.className = "spawn-card-image";
        img.style.backgroundImage = `url("${data.image}")`;

        // Body
        const body = document.createElement("div");
        body.className = "spawn-card-body";

        const title = document.createElement("h3");
        title.className = "spawn-card-title";
        title.textContent = data.title || key;

        const desc = document.createElement("p");
        desc.className = "spawn-card-desc";
        desc.textContent = data.description || "";

        const meta = document.createElement("div");
        meta.className = "spawn-card-meta";

        // Money
        const cur = data.currency || {};
        const moneyParts = [];
        if (cur.money) moneyParts.push(`$${cur.money}`);
        if (cur.gold)  moneyParts.push(`${cur.gold} Gold`);
        if (cur.rol)   moneyParts.push(`${cur.rol} RoL`);
        if (moneyParts.length) {
            const money = document.createElement("div");
            money.innerHTML = `<strong>${locale.spawn_starting_money || "Starting money"}:</strong> ${moneyParts.join(" · ")}`;
            meta.appendChild(money);
        }

        // Items
        if (Array.isArray(data.items) && data.items.length) {
            const itemsTitle = document.createElement("strong");
            itemsTitle.textContent = (locale.spawn_starting_items || "Starting items") + ":";
            const ul = document.createElement("ul");
            data.items.forEach(it => {
                const li = document.createElement("li");
                li.textContent = `${it.label || it.name} × ${it.amount}`;
                ul.appendChild(li);
            });
            meta.appendChild(document.createElement("br"));
            meta.appendChild(itemsTitle);
            meta.appendChild(ul);
        }

        body.appendChild(title);
        body.appendChild(desc);
        body.appendChild(meta);

        card.appendChild(img);
        card.appendChild(body);

        card.addEventListener("click", () => onSpawnPicked(key));

        grid.appendChild(card);
    }
}

async function onSpawnPicked(key) {
    state.spawnSelected = key;
    const res = await sendCallback("spawn:select", { spawn: key });
    if (!res.ok) return;

    if (res.nextStage === "rules") {
        buildRules();
        showStage("rules");
    } else if (res.nextStage === "quiz") {
        await sendCallback("quiz:request");
        showStage("quiz");
    }
    // "done" -> client closes the UI automatically (Lua side)
}

/* ─── STAGE: RULES ─────────────────────────────────────────── */

function buildRules() {
    const list = $("#rules-list");
    list.innerHTML = "";

    const rules = state.config.Rules || [];
    rules.forEach(r => {
        const item = document.createElement("div");
        item.className = "rule-item";

        const t = document.createElement("h3");
        t.className = "rule-title";
        t.textContent = r.title;

        const p = document.createElement("p");
        p.className = "rule-text";
        p.textContent = r.text;

        item.appendChild(t);
        item.appendChild(p);
        list.appendChild(item);
    });

    // Scroll-to-bottom detection
    const scroll = list;
    const btn    = $("#btn-accept-rules");
    const hint   = $("#rules-hint");
    btn.disabled = true;

    const checkScroll = () => {
        const atBottom = (scroll.scrollHeight - scroll.scrollTop - scroll.clientHeight) < 16;
        if (atBottom) {
            btn.disabled = false;
            hint.style.display = "none";
        }
    };
    // If the content is too short to scroll, unlock immediately
    if (scroll.scrollHeight <= scroll.clientHeight + 4) {
        btn.disabled = false;
        hint.style.display = "none";
    }
    scroll.addEventListener("scroll", checkScroll);
}

$("#btn-accept-rules").addEventListener("click", async () => {
    const res = await sendCallback("rules:accept");
    if (!res.ok) return;
    if (res.nextStage === "quiz") {
        showStage("quiz");
    }
    // "done" -> client closes the UI automatically (Lua side)
});

/* ─── STAGE: QUIZ ─────────────────────────────────────────── */

function startQuizTimer() {
    const cfg = state.config.Quiz || {};
    if (!state.config.Toggles.EnableQuizTimer) return;

    state.quiz.timeLeft = cfg.TimeSeconds || 180;
    const el = $("#quiz-time");
    el.style.display = "";

    const tick = () => {
        const t = state.quiz.timeLeft;
        el.textContent = fmtTime(t);
        if (t <= 30) el.classList.add("warn");
        if (t <= 0) {
            clearInterval(state.quiz.timerHandle);
            submitQuiz(true);
            return;
        }
        state.quiz.timeLeft--;
    };
    tick();
    state.quiz.timerHandle = setInterval(tick, 1000);
}

function renderQuestion(idx) {
    const q       = state.quiz.questions[idx];
    const total   = state.quiz.questions.length;
    const locale  = state.config.Locale  || {};
    const cfg     = state.config.Quiz    || {};

    $("#quiz-progress").textContent = (locale.quiz_question_progress || "Question %s of %s")
        .replace("%s", idx + 1).replace("%s", total);
    $("#quiz-mistakes").textContent = (locale.quiz_mistakes_left || "Mistakes allowed: %s")
        .replace("%s", cfg.MaxMistakesAllowed);

    const body = $("#quiz-body");
    body.innerHTML = "";

    const qText = document.createElement("div");
    qText.className = "question-text";
    qText.textContent = q.question;
    body.appendChild(qText);

    const list = document.createElement("div");
    list.className = "answer-list";

    q.answers.forEach((ans, i) => {
        const opt = document.createElement("div");
        opt.className = "answer-option";
        opt.textContent = ans;
        opt.dataset.index = (i + 1).toString();

        // Restore previous selection (if user navigates back)
        if (state.quiz.answers[idx + 1] === (i + 1)) {
            opt.classList.add("selected");
        }

        opt.addEventListener("click", () => {
            list.querySelectorAll(".answer-option").forEach(o => o.classList.remove("selected"));
            opt.classList.add("selected");
            state.quiz.answers[idx + 1] = i + 1;
        });
        list.appendChild(opt);
    });

    body.appendChild(list);

    // Adjust button label (last question = "Finish test")
    const btn = $("#btn-quiz-next");
    btn.querySelector("span").textContent = (idx === total - 1)
        ? (locale.quiz_submit_btn || "Finish test")
        : (locale.quiz_next_btn   || "Next question");
}

$("#btn-quiz-next").addEventListener("click", () => {
    const idx = state.quiz.currentIdx;
    if (state.quiz.answers[idx + 1] == null) {
        // Allow but visualize as a "shake" reminder to pick something
        $("#quiz-body").animate(
            [{ transform: "translateX(-6px)" }, { transform: "translateX(6px)" }, { transform: "translateX(0)" }],
            { duration: 200, iterations: 2 }
        );
        return;
    }
    if (idx + 1 >= state.quiz.questions.length) {
        submitQuiz(false);
    } else {
        state.quiz.currentIdx++;
        renderQuestion(state.quiz.currentIdx);
    }
});

async function submitQuiz(timeUp) {
    if (state.quiz.timerHandle) {
        clearInterval(state.quiz.timerHandle);
        state.quiz.timerHandle = null;
    }
    await sendCallback("quiz:submit", {
        answers: state.quiz.answers,
        timeUp:  !!timeUp,
    });
    // Wait for the "QuizResult" event coming from the server -> quiz:result action
}

function showQuizResult(result) {
    const locale = state.config.Locale || {};
    const card   = $("#result-card");
    const title  = $("#result-title");
    const sub    = $("#result-sub");
    const stats  = $("#result-stats");
    const icon   = $("#result-icon");

    if (result.passed) {
        card.classList.remove("failed");
        title.textContent = locale.quiz_passed_title    || "Passed!";
        sub.textContent   = locale.quiz_passed_subtitle || "Welcome!";
        icon.textContent  = "✓";
    } else {
        card.classList.add("failed");
        title.textContent = locale.quiz_failed_title    || "Failed";
        sub.textContent   = result.timeUp
            ? (locale.quiz_time_up || "Time's up!")
            : (locale.quiz_failed_subtitle || "You did not pass the test.");
        icon.textContent  = "✗";
    }

    stats.textContent = `${result.total - result.mistakes} / ${result.total} correct`;
    showStage("result");
}

/* ─── NUI MESSAGE HANDLING ─────────────────────────────────── */

window.addEventListener("message", (event) => {
    const msg = event.data;
    if (!msg || !msg.action) return;

    switch (msg.action) {

        case "open": {
            state.config = msg.config;
            applyDesign(msg.config.Design);
            applyLocale(msg.config.Locale);
            buildSpawnCards();

            // Initial stage
            const stage = msg.stage || "spawn";
            showStage(stage);

            $("#app").style.display = "";
            break;
        }

        case "close": {
            $("#app").style.display = "none";
            // Reset state for the next time the UI opens
            state.spawnSelected = null;
            state.quiz = { questions: [], currentIdx: 0, answers: {}, timeLeft: 0, timerHandle: null };
            break;
        }

        case "quiz:start": {
            state.quiz.questions = msg.questions || [];
            state.quiz.currentIdx = 0;
            state.quiz.answers = {};
            renderQuestion(0);
            startQuizTimer();
            showStage("quiz");
            break;
        }

        case "quiz:result": {
            showQuizResult(msg.result);
            break;
        }

        default: break;
    }
});

window.addEventListener("load", () => {
    sendCallback("ui:ready");
});

})();
