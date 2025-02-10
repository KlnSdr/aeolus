package aeolus.readings.quality;

import dobby.util.logging.Logger;

import java.util.Calendar;

public class DataQualityCheckerDispatcher {
    private static final Logger LOGGER = new Logger(DataQualityCheckerDispatcher.class);
    private static final CheckerConfigService service = CheckerConfigService.getInstance();
    private static DataQualityCheckerDispatcher instance;

    private DataQualityCheckerDispatcher() {
    }

    public static DataQualityCheckerDispatcher getInstance() {
        if (instance == null) {
            instance = new DataQualityCheckerDispatcher();
        }
        return instance;
    }

    public void run() {
        for (CheckerConfig config : service.findAll()) {
            if (!config.isEnabled()) {
                continue;
            }

            if (!shouldRun(config)) {
                continue;
            }

            runForUser(config);
        }
    }

    private void runForUser(CheckerConfig config) {
        try {
            final CheckerStatus status = new DataQualityChecker(config.getUserId()).runCheck();
            config.setLastRunStatus(status);
            updateLastRunTime(config);
            service.save(config);
        } catch (Exception e) {
            LOGGER.error("an error occurred while checking data integrity");
            LOGGER.trace(e);
        }
    }

    private void updateLastRunTime(CheckerConfig config) {
        final Calendar now = Calendar.getInstance();

        config.setLastRunDay(now.get(Calendar.DAY_OF_MONTH));
        config.setLastRunMonth(now.get(Calendar.MONTH) + 1);
        config.setLastRunYear(now.get(Calendar.YEAR));

        config.setLastRunHour(now.get(Calendar.HOUR_OF_DAY));
        config.setLastRunMinute(now.get(Calendar.MINUTE));
    }

    private boolean shouldRun(CheckerConfig config) {
        final Calendar now = Calendar.getInstance();
        if (config.getLastRunDay() == now.get(Calendar.DAY_OF_MONTH) && config.getLastRunMonth() == now.get(Calendar.MONTH) + 1 && config.getLastRunYear() == now.get(Calendar.YEAR)) {
            return false;
        }

        if (now.get(Calendar.HOUR_OF_DAY) < config.getStartHour()) {
            return false;
        }

        final int diff = config.getStartMinute() - now.get(Calendar.MINUTE);

        return diff <= 0;
    }
}
