package aeolus.updates;

import aeolus.readings.service.TariffService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import hades.update.Update;
import thot.connector.IConnector;

@RegisterFor(AddTariffBucketUpdate.class)
public class AddTariffBucketUpdate implements Update {
    private final IConnector connector;

    @Inject
    public AddTariffBucketUpdate(IConnector connector) {
        this.connector = connector;
    }

    @Override
    public boolean run() {
        return connector.create(TariffService.BUCKET_NAME);
    }

    @Override
    public String getName() {
        return "aeolus_AddTariffBucketUpdate";
    }

    @Override
    public int getOrder() {
        return UPDATE_ORDER.TARIFF_BUCKET.getOrder();
    }
}
