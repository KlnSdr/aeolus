package aeolus.updates;

import aeolus.readings.service.ReadingService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import hades.update.Update;
import thot.connector.IConnector;

@RegisterFor(AddLastReadingBucketUpdate.class)
public class AddLastReadingBucketUpdate implements Update {
    private final IConnector connector;

    @Inject
    public AddLastReadingBucketUpdate(IConnector connector) {
        this.connector = connector;
    }

    @Override
    public boolean run() {
        return connector.create(ReadingService.bucketNameLastReading);
    }

    @Override
    public String getName() {
        return "aeolus_AddLastReadingBucketUpdate";
    }

    @Override
    public int getOrder() {
        return UPDATE_ORDER.LAST_READING_BUCKET.getOrder();
    }
}
