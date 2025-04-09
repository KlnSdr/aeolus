package aeolus.readings.quality;

import aeolus.readings.quality.service.CheckerConfigService;
import common.logger.Logger;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

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

            try {
                if (!shouldRun(config)) {
                    continue;
                }

                runForUser(config);
            } catch (Exception e) {
                LOGGER.error("an error occurred while checking data integrity");
                LOGGER.trace(e);
            }
        }
    }

    public void runForUser(CheckerConfig config) {
        final CheckerStatus status = new DataQualityChecker(config.getUserId()).runCheck();
        config.setLastRunStatus(status);
        updateLastRunTime(config);
        service.save(config);
    }

    private void updateLastRunTime(CheckerConfig config) {
        final Calendar now = Calendar.getInstance();

        config.setLastRunDay(now.get(Calendar.DAY_OF_MONTH));
        config.setLastRunMonth(now.get(Calendar.MONTH) + 1);
        config.setLastRunYear(now.get(Calendar.YEAR));

        config.setLastRunHour(now.get(Calendar.HOUR_OF_DAY));
        config.setLastRunMinute(now.get(Calendar.MINUTE));
    }

    private boolean shouldRun(CheckerConfig config) throws ParseException {
        final Calendar now = Calendar.getInstance();
        SimpleDateFormat format = new SimpleDateFormat("HH:mm");

        final Date currentDate = format.parse(now.get(Calendar.HOUR_OF_DAY) + ":" + now.get(Calendar.MINUTE));
        final Date startDate = format.parse(config.getStartHour() + ":" + config.getStartMinute());

        final int diff = (int) ((currentDate.getTime() - startDate.getTime()) / 60000);

        return diff >= 0 && diff < 5;
    }
}
