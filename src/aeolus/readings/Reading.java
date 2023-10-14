package aeolus.readings;

import java.io.Serializable;
import java.util.Date;

public class Reading implements Serializable {
    private final float value;
    private final Date date;

    public Reading(float value, Date date) {
        this.value = value;
        this.date = date;
    }

    public float getValue() {
        return value;
    }

    public Date getDate() {
        return date;
    }
}
