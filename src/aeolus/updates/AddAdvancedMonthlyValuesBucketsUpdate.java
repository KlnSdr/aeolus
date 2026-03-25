package aeolus.updates;

import aeolus.readings.service.MonthlyValuesService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import hades.update.Update;
import thot.connector.IConnector;

@RegisterFor(AddAdvancedMonthlyValuesBucketsUpdate.class)
public class AddAdvancedMonthlyValuesBucketsUpdate implements Update {
    private final IConnector connector;

    @Inject
    public AddAdvancedMonthlyValuesBucketsUpdate(IConnector connector) {
        this.connector = connector;
    }

    @Override
    public boolean run() {
        final String[] bucketNames = new String[]{MonthlyValuesService.BUCKET_NAME_TEMPORARY, MonthlyValuesService.BUCKET_NAME_PREVIOUS_CUMULATIVE};

        for (String bucketName : bucketNames) {
            if (!connector.write(bucketName, "TEST", "") || !connector.delete(bucketName, "TEST")) {
                return false;
            }
        }
        return true;
    }

    @Override
    public String getName() {
        return "aeolus_add_advanced_monthly_values_buckets_update";
    }

    @Override
    public int getOrder() {
        return UPDATE_ORDER.ADVANCED_MONTHLY_VALUES_BUCKET.getOrder();
    }
}
