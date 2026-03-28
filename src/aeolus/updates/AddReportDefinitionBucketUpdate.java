package aeolus.updates;

import aeolus.reports.service.ReportService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import hades.update.Update;
import thot.connector.IConnector;

@RegisterFor(AddReportDefinitionBucketUpdate.class)
public class AddReportDefinitionBucketUpdate implements Update {
    private final IConnector connector;

    @Inject
    public AddReportDefinitionBucketUpdate(IConnector connector) {
        this.connector = connector;
    }

    @Override
    public boolean run() {
        return connector.write(ReportService.BUCKET_NAME, "TEST", "") && connector.delete(ReportService.BUCKET_NAME, "TEST");
    }

    @Override
    public String getName() {
        return "aeolus-report-definition-bucket-update";
    }

    @Override
    public int getOrder() {
        return UPDATE_ORDER.REPORT_DEFINITIONS_BUCKET.getOrder();
    }
}
