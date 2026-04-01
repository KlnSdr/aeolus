package aeolus.reports.service;

import aeolus.reports.Report;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.util.json.NewJson;
import thot.connector.IConnector;
import thot.janus.Janus;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@RegisterFor(ReportService.class)
public class ReportService {
    private final IConnector connector;
    public static final String BUCKET_NAME = "aeolus_reports";

    @Inject
    public ReportService(IConnector connector) {
        this.connector = connector;
    }

    public boolean update(Report report) {
        return connector.write(BUCKET_NAME, report.getKey(), report.toJson());
    }

    public boolean delete(Report report) {
        return connector.delete(BUCKET_NAME, report.getKey());
    }

    public Report find(UUID owner, UUID id) {
        return Janus.parse(connector.read(BUCKET_NAME, owner + "_" + id, NewJson.class), Report.class);
    }

    public Report[] find(UUID owner) {
        final NewJson[] jsons = connector.readPattern(BUCKET_NAME, owner + "_.*", NewJson.class);
        final List<Report> reports = new ArrayList<>();
        for (NewJson json : jsons) {
            reports.add(Janus.parse(json, Report.class));
        }
        return reports.toArray(new Report[0]);
    }

    public Report[] findAll() {
        final NewJson[] jsons = connector.readPattern(BUCKET_NAME, ".*", NewJson.class);
        final List<Report> reports = new ArrayList<>();
        for (NewJson json : jsons) {
            reports.add(Janus.parse(json, Report.class));
        }
        return reports.toArray(new Report[0]);
    }
}
