package aeolus.updates;

import aeolus.readings.service.MonthlyValuesService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import hades.update.Update;
import thot.connector.IConnector;

@RegisterFor(AddMonthlyValuesBucketUpdate.class)
public class AddMonthlyValuesBucketUpdate implements Update {
    private final IConnector  connector;

    @Inject
    public AddMonthlyValuesBucketUpdate(IConnector connector) {
        this.connector = connector;
    }

    @Override
    public boolean run() {
        return connector.write(MonthlyValuesService.BUCKET_NAME, "TEST", "") && connector.delete(MonthlyValuesService.BUCKET_NAME, "TEST");
    }

    @Override
    public String getName() {
        return "aeolus_create_monthly_values_bucket_update";
    }

    @Override
    public int getOrder() {
        return UPDATE_ORDER.MONTHLY_VALUES_BUCKET.getOrder();
    }
}
