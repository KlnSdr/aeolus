package aeolus.updates;

import aeolus.readings.quality.service.CheckerConfigService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import hades.update.Update;
import thot.connector.IConnector;

@RegisterFor(AddCheckerConfigBucketUpdate.class)
public class AddCheckerConfigBucketUpdate implements Update {
    private final IConnector connector;

    @Inject
    public AddCheckerConfigBucketUpdate(IConnector connector) {
        this.connector = connector;
    }

    @Override
    public boolean run() {
        return connector.write(CheckerConfigService.BUCKET_NAME, "TEST", "") && connector.delete(CheckerConfigService.BUCKET_NAME, "TEST");
    }

    @Override
    public String getName() {
        return "aeolus_create_checker_bucket";
    }

    @Override
    public int getOrder() {
        return UPDATE_ORDER.CHECKER_CONFIG_BUCKET.getOrder();
    }
}
