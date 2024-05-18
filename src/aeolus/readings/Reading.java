package aeolus.readings;

import aeolus.util.IsoDate;
import dobby.util.json.NewJson;
import janus.DataClass;
import janus.annotations.JanusString;

import java.io.Serializable;
import java.util.Date;

public class Reading implements DataClass {
    // TODO change correct types once janus supports them
    @JanusString("value")
    private String value;
    @JanusString("date")
    private String date;

    public Reading(float value, Date date) {
        this.value = Double.toString(value);
        this.date = IsoDate.toIsoDateString(date);
    }

    public Reading() {

    }

    public double getValue() {
        return Double.parseDouble(this.value);
    }

    public Date getDate() {
        return IsoDate.parseIsoDate(this.date);
    }

    @Override
    public String getKey() {
        return date;
    }

    @Override
    public NewJson toJson() {
        final NewJson json = new NewJson();
        json.setString("date", date);
        json.setFloat("value", getValue());
        return json;
    }

    public NewJson toStoreJson() {
        final NewJson json = new NewJson();
        json.setString("date", date);
        json.setString("value", value);
        return json;
    }
}
