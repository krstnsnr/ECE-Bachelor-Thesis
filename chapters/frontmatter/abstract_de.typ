CrazyCar ist ein kleines autonomes Rennauto, das an der FH JOANNEUM in Lehre und
Forschung zu Embedded Systems eingesetzt wird. Diese Arbeit entwickelt die
Applikations-Firmware für eine neue Hardware-Generation dieser Plattform auf
Basis eines STM32H533RE-Mikrocontrollers und bindet sie an das AI-MotionLab an,
ein Motion-Capture-Labor, das als gemeinsame Testumgebung dient.

Die Firmware nimmt die Sensoren und Aktoren der Plattform in Betrieb. Auf der
Eingangsseite liest sie drei Time-of-Flight-Distanzsensoren, eine Inertial
Measurement Unit, einen externen ADC und einen Hall-Sensor für die Raddrehzahl
aus. Auf der Ausgangsseite regelt sie den Antriebsmotor und die Lenkung. Auf
diesen Treibern setzt eine State Machine auf, die das Auto autonom über die
Strecke fährt. Sie erkennt Kurven anhand der auf den zurückgelegten Weg
normierten Änderungsrate der seitlichen Distanzwerte und lenkt durch sie
hindurch. Ein flagbasierter Event-Mechanismus behandelt einen Crash, ein
festsitzendes Auto oder einen niedrigen Batteriestand.

Damit sich das Auto testen und tunen lässt, stellt die Firmware ihre Telemetrie
und ihre Regelparameter als benannte Felder bereit, die zur Laufzeit gelesen und
geschrieben werden können, und lässt sich over-the-air neu flashen. Die
AI-MotionLab-Testsuite kann das Auto dadurch beobachten und seine PID-Parameter
während der Fahrt anpassen, sodass eine Änderung bereits im nächsten Regelschritt
wirksam wird, ohne erneutes Kompilieren und ohne Kabelverbindung. Bei der
erstmaligen Inbetriebnahme der zuvor ungetesteten Hardware zeigten sich zudem
mehrere Schwachstellen im Design der Hauptplatine, die im Rahmen der Evaluierung
dokumentiert werden.

Das Ergebnis ist eine CrazyCar-Plattform, die autonom fährt und einen schnellen,
reproduzierbaren Test- und Tuning-Workflow unterstützt. Sie löst damit den
langsamen Zyklus aus Editieren, Kompilieren und Neuflashen der vorherigen
Generation ab. In den aufgezeichneten Testfahrten wurden 134 von 137 Runden als
gültig gewertet. Bei gleicher Geschwindigkeitseinstellung lag die Rundenzeit im
Mittel bei 10,55 s mit einer Standardabweichung von 0,10 s.
