package aeolus.readings.quality;

import dobby.util.json.NewJson;
import janus.Janus;
import thot.connector.Connector;

import java.util.ArrayList;

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

    public boolean save(CheckerConfig config) {
        return Connector.write(BUCKET_NAME, config.getKey(), config.toJson());
    }
}
