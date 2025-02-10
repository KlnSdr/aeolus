package aeolus.updates;

import aeolus.readings.quality.CheckerConfigService;
import aeolus.readings.service.ReadingService;
import hades.update.Update;
import thot.connector.Connector;

public class AddCheckerConfigBucketUpdate implements Update {
    @Override
    public boolean run() {
        return Connector.write(CheckerConfigService.BUCKET_NAME, "TEST", "") && Connector.delete(CheckerConfigService.BUCKET_NAME, "TEST");
    }

    @Override
    public String getName() {
        return "aeolus_create_checker_bucket";
    }

    @Override
    public int getOrder() {
        return 1;
    }
}
