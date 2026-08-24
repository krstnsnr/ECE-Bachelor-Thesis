CrazyCar ist ein kleines autonomes Rennauto, das an der FH JOANNEUM in Lehre und
Forschung zu Embedded Systems eingesetzt wird. Diese Arbeit entwickelt die
Applikations-Firmware für eine neue Hardware-Generation dieser Plattform auf
Basis eines STM32H533RE Microcontrollers und bindet sie an das AI-MotionLab an,
ein Motion-Capture-Labor, das als gemeinsame Testumgebung dient.

Die Firmware nimmt die Sensoren und Aktoren der Plattform in Betrieb. Auf der
Eingangsseite steuert sie mehrere Time-of-Flight-Distanzsensoren, eine Inertial
Measurement Unit, einen externen ADC und einen Hall-Sensor für die Raddrehzahl
an. Auf der Ausgangsseite regelt sie den Antriebsmotor und die Lenkung. Darauf
setzt eine State Machine auf, die das Auto autonom über die Strecke fährt. Sie
erkennt Kurven anhand der Änderungsrate der seitlichen Distanzsensoren, lenkt 
und reagiert über einen flag basierten Event-Mechanismus auf einen Crash,
ein festsitzendes Auto oder eine leere Batterie.

Damit sich das Auto testen und tunen lässt, stellt die Firmware ihre Telemetrie
und ihre Regelparameter als benannte Felder bereit, die zur Laufzeit gelesen und
geschrieben werden können, und lässt sich over-the-air neu flashen. So kann die
AI-MotionLab-Testsuite das Auto beobachten und seine PID-Gains während der Fahrt
anpassen, wobei eine Änderung im nächsten Regelschritt wirkt, ohne Neubau und
ohne Kabelverbindung. Bei der erstmaligen Inbetriebnahme der zuvor ungetesteten
Hardware kamen mehrere Design-Schwachstellen des Mainboards zum Vorschein, die im
Rahmen der Evaluierung dokumentiert werden.

Das Ergebnis ist eine CrazyCar-Plattform, die autonom fährt und einen schnellen,
reproduzierbaren Test- und Tuning-Workflow unterstützt. Sie löst damit den
langsamen Edit-Compile-Reflash-Zyklus der vorherigen Generation ab.