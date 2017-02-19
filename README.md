# rafale_mode
CA UIM Rafale_mode for NAS (actually used in production)

**Alarm message pattern required**

```
Alarm message [interval in second][numbers of occurence][severity]
```

For example you dont want a new alarm when a message is triggered a lot of time, but you need a alarm if this alarm is triggered **60 times** in less than **5 minutes** with a **severity of 3**. So you update your logmon alarm message for : 

```
Alarm message [300][60][3]
``` 

> 300 because 5 minutes equal 300 seconds.

And now you get your alarm at the right time and with the right condition (without rafale).

> **Warning** This script is not ok for a big CA UIM infrastructure (Like 60msg /s and more). This will slow down to much the NAS.
