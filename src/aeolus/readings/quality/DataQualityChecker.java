package aeolus.readings.quality;

import aeolus.readings.service.ReadingService;
import dobby.util.logging.Logger;
import hades.messaging.service.MessageService;

import java.util.Calendar;
import java.util.UUID;

public class DataQualityChecker {
    private static final ReadingService service = ReadingService.getInstance();
    private static final Logger LOGGER = new Logger(DataQualityChecker.class);
    private final UUID userId;

    public DataQualityChecker(UUID userId) {
        this.userId = userId;
    }

    public CheckerStatus runCheck() {
        final Calendar now = Calendar.getInstance();

        try {
            service.find(userId, now.get(Calendar.YEAR), now.get(Calendar.MONTH) + 1, now.get(Calendar.DAY_OF_MONTH));
            return CheckerStatus.OK;
        } catch (NullPointerException e) {
            MessageService.getInstance().update(MessageService.getInstance().newSystemMessage(userId, "Missing entry for " + now.get(Calendar.YEAR) + "-" + (now.get(Calendar.MONTH) + 1) + "-" + now.get(Calendar.DAY_OF_MONTH)));
            return CheckerStatus.WARNING;
        } catch (Exception e) {
            LOGGER.error("an error occurred while checking data integrity");
            LOGGER.trace(e);
            return CheckerStatus.ERROR;
        }
    }
}
