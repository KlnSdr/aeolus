package aeolus.updates;

import aeolus.readings.service.ReadingService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import hades.update.Update;
import thot.connector.IConnector;

@RegisterFor(CreateBucketUpdate.class)
public class CreateBucketUpdate implements Update {
    private final IConnector connector;

    @Inject
    public CreateBucketUpdate(IConnector connector) {
        this.connector = connector;
    }

    @Override
    public boolean run() {
        return connector.write(ReadingService.bucketName, "TEST", "") && connector.delete(ReadingService.bucketName, "TEST");
    }

    @Override
    public String getName() {
        return "aeolus_create_bucket";
    }

    @Override
    public int getOrder() {
        return UPDATE_ORDER.CREATE_BUCKETS.getOrder();
    }
}
