-- qb-atmtechnician database tables
-- Import this into your qbcore database before starting the resource

CREATE TABLE IF NOT EXISTS `atmtechnician_cooldowns` (
  `atm_id` VARCHAR(64) NOT NULL,
  `last_repaired` DATETIME NOT NULL,
  PRIMARY KEY (`atm_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `atmtechnician_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `atm_id` VARCHAR(64) NOT NULL,
  `success` TINYINT(1) NOT NULL DEFAULT 0,
  `payout` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `atmtechnician_grades` (
  `citizenid` VARCHAR(50) NOT NULL,
  `xp` INT NOT NULL DEFAULT 0,
  `grade` TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
