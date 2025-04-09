package aeolus.readings.quality.service;

import aeolus.readings.quality.CheckerConfig;
import aeolus.readings.quality.CheckerStatus;
import dobby.util.json.NewJson;
import thot.connector.Connector;
import thot.janus.Janus;

import java.util.ArrayList;
import java.util.UUID;

public class CheckerConfigService {
    public static final String BUCKET_NAME = "aeolus_checker_config";
    private static CheckerConfigService instance;

    private CheckerConfigService() {
    }

    public static CheckerConfigService getInstance() {
        if (instance == null) {
            instance = new CheckerConfigService();
        }
        return instance;
    }

    public CheckerConfig[] findAll() {
        final NewJson[] jsonConfigs = Connector.readPattern(BUCKET_NAME, ".*", NewJson.class);
        final ArrayList<CheckerConfig> configs = new ArrayList<>();

        for (NewJson json : jsonConfigs) {
            if (json == null) {
                continue;
            }
            configs.add(Janus.parse(json, CheckerConfig.class));
        }

        return configs.toArray(new CheckerConfig[0]);
    }

    public CheckerConfig findByUser(UUID userId) {
        return Janus.parse(Connector.read(BUCKET_NAME, userId.toString(), NewJson.class), CheckerConfig.class);
    }

    public boolean save(CheckerConfig config) {
        return Connector.write(BUCKET_NAME, config.getKey(), config.toStoreJson());
    }

    public CheckerConfig create(UUID userId) {
        final CheckerConfig config = new CheckerConfig();
        config.setUserId(userId);
        config.setEnabled(false);
        config.setStartHour(0);
        config.setStartMinute(0);
        config.setLastRunDay(0);
        config.setLastRunMonth(0);
        config.setLastRunYear(0);
        config.setLastRunHour(0);
        config.setLastRunMinute(0);
        config.setLastRunStatus(CheckerStatus.NO_DATA);
        return config;
    }
}
