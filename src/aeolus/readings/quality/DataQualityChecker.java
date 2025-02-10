package aeolus.readings.quality;

import java.util.UUID;

public class DataQualityChecker {
    private final UUID userId;

    public DataQualityChecker(UUID userId) {
        this.userId = userId;
    }

    public CheckerStatus runCheck() {
        // TODO
        System.out.println("checking...");
        return CheckerStatus.NO_DATA;
    }
}
