-- ╔══════════════════════════════════════════════════════════════════╗
-- ║   J0K3R-whitelist_spawnselector - SQL Install                    ║
-- ║   Run this once on your VORP database.                           ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Whitelist status table (created by this resource)
CREATE TABLE IF NOT EXISTS `j0k3r_whitelist` (
    `id`             INT(11)      NOT NULL AUTO_INCREMENT,
    `identifier`     VARCHAR(50)  NOT NULL,                  -- license:xxx (preferred) or steam:xxx
    `charidentifier` INT(11)      DEFAULT NULL,              -- VORP charIdentifier (NULL/0 for "first" or "perplayer" policy)
    `passed`         TINYINT(1)   NOT NULL DEFAULT 0,
    `chosen_spawn`   VARCHAR(64)  DEFAULT NULL,              -- key from Config.Spawns
    `passed_at`      TIMESTAMP    NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_ident_char` (`identifier`, `charidentifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ┌──────────────────────────────────────────────────────────────────┐
-- │   BAN MECHANIC                                                   │
-- │                                                                  │
-- │   No separate `bans` table is needed. VORP stores bans directly  │
-- │   in the existing `users` table using these columns:             │
-- │     - banned       TINYINT(1)                                    │
-- │     - banneduntil  INT(10)        (Unix timestamp)               │
-- │   These columns are created by VORP Core, no action required.    │
-- │                                                                  │
-- │   If for some reason your `users` table is missing these         │
-- │   columns, run the (commented-out) statement below as a fallback:│
-- │                                                                  │
-- │   ALTER TABLE `users`                                            │
-- │     ADD COLUMN IF NOT EXISTS `banned`      TINYINT(1) DEFAULT 0, │
-- │     ADD COLUMN IF NOT EXISTS `banneduntil` INT(10)    DEFAULT 0; │
-- └──────────────────────────────────────────────────────────────────┘
