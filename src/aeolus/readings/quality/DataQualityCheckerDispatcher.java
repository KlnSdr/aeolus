package aeolus.readings.quality;

import aeolus.readings.quality.service.CheckerConfigService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import common.logger.Logger;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

@RegisterFor(DataQualityCheckerDispatcher.class)
public class DataQualityCheckerDispatcher {
    private static final Logger LOGGER = new Logger(DataQualityCheckerDispatcher.class);
    private final CheckerConfigService service;
    private final DataQualityChecker dataQualityChecker;

    @Inject
    public DataQualityCheckerDispatcher(CheckerConfigService service, DataQualityChecker dataQualityChecker) {
        this.service = service;
        this.dataQualityChecker = dataQualityChecker;
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
        final CheckerStatus status = dataQualityChecker.runCheck(config.getUserId());
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
