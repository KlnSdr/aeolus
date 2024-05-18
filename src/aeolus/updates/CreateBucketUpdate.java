package aeolus.updates;

import aeolus.readings.service.ReadingService;
import hades.update.Update;
import thot.connector.Connector;

public class CreateBucketUpdate implements Update {
    @Override
    public boolean run() {
        return Connector.write(ReadingService.bucketName, "TEST", "") && Connector.delete(ReadingService.bucketName, "TEST");
    }

    @Override
    public String getName() {
        return "aeolus_create_bucket";
    }

    @Override
    public int getOrder() {
        return 0;
    }
}
