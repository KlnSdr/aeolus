package aeolus.reports;

import dobby.util.json.NewJson;
import thot.janus.DataClass;
import thot.janus.annotations.JanusInteger;
import thot.janus.annotations.JanusList;
import thot.janus.annotations.JanusString;
import thot.janus.annotations.JanusUUID;

import java.util.List;
import java.util.UUID;

public class Report implements DataClass {
    @JanusUUID("id")
    private UUID id;
    @JanusUUID("owner")
    private UUID owner;
    @JanusString("reportType")
    private String reportType;
    @JanusString("name")
    private String name;
    @JanusList("reportFeatures")
    private List<String> reportFeatures;
    @JanusString("trigger")
    private String trigger;
    @JanusString("scheduleDay")
    private String reportScheduleDay;
    @JanusInteger("scheduleHour")
    private int scheduleHour;
    @JanusInteger("scheduleMinute")
    private int scheduleMinute;

    public Report() {
        id  = UUID.randomUUID();
    }

    public void setReportType(ReportType reportType) {
        this.reportType = reportType.name();

    }

    public ReportType getReportType() {
        return ReportType.valueOf(reportType);
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setOwner(UUID owner) {
        this.owner = owner;
    }

    public UUID getOwner() {
        return owner;
    }

    public void setReportFeatures(List<ReportFeatures> reportFeatures) {
        this.reportFeatures = reportFeatures.stream().map(ReportFeatures::name).toList();
    }

    public List<ReportFeatures> getReportFeatures() {
        return reportFeatures.stream().map(ReportFeatures::valueOf).toList();
    }

    public void setTrigger(TriggerType trigger) {
        this.trigger = trigger.name();
    }

    public TriggerType getTrigger() {
        return TriggerType.valueOf(trigger);
    }

    public void setReportScheduleDay(ReportScheduleDay reportScheduleDay) {
        this.reportScheduleDay = reportScheduleDay.name();
    }

    public ReportScheduleDay getReportScheduleDay() {
        return ReportScheduleDay.valueOf(reportScheduleDay);
    }

    public void setScheduleHour(int scheduleHour) {
        this.scheduleHour = scheduleHour;
    }

    public int getScheduleHour() {
        return scheduleHour;
    }

    public void setScheduleMinute(int scheduleMinute) {
        this.scheduleMinute = scheduleMinute;
    }

    public int getScheduleMinute() {
        return scheduleMinute;
    }

    @Override
    public String getKey() {
        return owner + "_"  + id;
    }

    @Override
    public NewJson toJson() {
        final NewJson json =  new NewJson();
        json.setString("id", id.toString());
        json.setString("owner", owner.toString());
        json.setString("reportType", reportType);
        json.setString("name", name);
        json.setList("reportFeatures", reportFeatures.stream().map(s -> (Object) s).toList());
        json.setString("trigger", trigger);
        json.setString("scheduleDay", reportScheduleDay);
        json.setInt("scheduleHour", scheduleHour);
        json.setInt("scheduleMinute", scheduleMinute);
        return json;
    }
}
