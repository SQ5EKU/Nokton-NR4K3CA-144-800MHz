' Program do sterowania PLL UMA1014T w nadajniku Nokton NR4K3CA (TX160v7) , z procesorem 89C51
' Czestotliwosc pracy: 144.800 MHz i 144.950 MHz
' Wersja z watchdogiem zasilania , kontrola poprawnej synchronizacji PLL ,
' zabezpieczeniem w przypadku uszkodzenia procesora (nie stoi nosna na przypadkowej czestotliwosci),
' antyzwiecha sprzetowa 5 sekudowa
' http://sq5eku.blogspot.com

$regfile = "REG51.DAT"
$crystal = 18432000                                           ' zegar 18.432 MHz

Config Sda = P2.7                                             ' pin 28 , magistrala I2C , SDA
Config Scl = P2.6                                             ' pin 27 , magistrala I2C , SCL

Dim Tmp As Bit                                                ' odcinanie nadawania po jednej rundzie

Ch Alias P0.1                                                 ' pin 38 , 144.800 MHz H=stan spoczynku , 144.950 MHz L=zwarte do masy
Ptt Alias P0.2                                                ' pin 37 , PTT H=wylaczone , L=zalaczone
Ld Alias P0.7                                                 ' pin 32 , LD UMA1014T H=synchronizacja , L=brak synchronizacji
Vco Alias P2.2                                                ' pin 23 , zasilanie VCO H=zalaczone , L=wylaczone
Drv Alias P2.3                                                ' pin 24 , wzmacniacz w.cz. H=wylaczony , L=zalaczony
Vbat Alias P2.4                                               ' pin 25 , VBAT H=niskie napiecie zasilania , L=napiecie OK
Led Alias P2.5                                                ' pin 26 , LED TX H=zgaszona , L=swieci
Azw Alias P3.7                                                ' pin 17 , antyzwiecha

Set Ptt
Set Ch
Reset Vco
Tmp = 1
Set Azw
Set Drv
Set Vbat
Set Led
Set Ld

Declare Sub Pll_800
Declare Sub Pll_950
Declare Sub Pll_off
Declare Sub Pll_sw1
Declare Sub Pll_sw2

Do                                                            ' start petli
Reset Azw                                                     ' resetuj antyzwieche niskim stanem
' If Vbat = 0 Then                                             ' jezeli VBAT OK idz dalej , niski stan
  If Tmp = 0 Then                                             ' jezeli wartosc 0 idz dalej
   If Ptt = 0 Then                                            ' jezeli PTT zalaczone , niski stan
   Waitms 20
   If Ptt = 0 Then                                            ' dla stanow nieustalonych sprawdz ponownie PTT
   Set Vco                                                    ' wlacz zasilanie VCO
   Waitms 10
    If Ch = 1 Then                                            ' dla 144.800 MHz
    Gosub Pll_800
    End If
    If Ch = 0 Then
    Gosub Pll_950                                             ' dla 144.950 MHz
    End If
   Gosub Pll_sw1
   End If
  End If
  End If
' End If

 If Ptt = 1 Then                                              ' jezeli PTT wylaczone idz dalej , wysoki stan
  If Tmp = 1 Then                                             ' jezeli wartosc 1 idz dalej
  Waitms 10
  Gosub Pll_off
  Gosub Pll_sw2
  End If
 End If

Set Azw                                                       ' antyzwiecha pullup
Loop
End


Pll_800:
' Programowanie UMA1014T przez I2C
' Ustawianie parametrow PLL nadajnika dla 144.800 MHz
I2cstart                                                      ' start
I2cwbyte &B11000100                                           ' device address , SAA pin at +5V , write
I2cwbyte &B00001000                                           ' disable alarm , auto-increment , following register A
I2cwbyte &B00001100                                           ' no power down , current 0.5mA , reference divider 1024
I2cwbyte &B10100100                                           ' passive filter , VCO A
I2cwbyte &B00101101                                           ' main divider - high byte (144.800 MHz)
I2cwbyte &B01000000                                           ' main divider - low byte (144.800 MHz)
I2cstop                                                       ' stop
Return

Pll_950:
' Programowanie UMA1014T przez I2C
' Ustawianie parametrow PLL nadajnika  dla 144.950 MHz
I2cstart                                                      ' start
I2cwbyte &B11000100                                           ' device address , SAA pin at +5V , write
I2cwbyte &B00001000                                           ' disable alarm , auto-increment , following register A
I2cwbyte &B00001100                                           ' no power down , current 0.5mA , reference divider 1024
I2cwbyte &B10100100                                           ' passive filter , VCO A
I2cwbyte &B00101101                                           ' main divider - high byte (144.950 MHz)
I2cwbyte &B01001100                                           ' main divider - low byte (144.950 MHz)
I2cstop                                                       ' stop
Return

Pll_sw1:
' Ustawienia wyjsc podczas nadawania
Waitms 60
 If Ld = 1 Then                                               ' jezeli LD UMA1014T OK idz dalej , wysoki stan
 Reset Led                                                    ' zaswiec LED tx , niski stan
 Tmp = 1                                                      ' wpisz wartosc 1
 Reset Drv                                                    ' zalacz wzmacniacz w.cz.
 Else                                                         ' w przeciwnym wypadku idz do procedury Pll_off ---
 Goto Pll_off                                                 ' --- powtarzajac sekwencje trybu uspienia UMA1014T ---
 End If                                                       ' --- czasem UMA1014T nie startuje poprawnie.
Return

Pll_off:
' Programowanie UMA1014T przez I2C
' Ustawianie ukladu w tryb power down (UMA1014T pobiera okolo 3mA)
I2cstart                                                      ' start
I2cwbyte &B11000100                                           ' device address , SAA pin at +5V , write
I2cwbyte &B00001000                                           ' disable alarm , auto-increment , following register A
I2cwbyte &B10000000                                           ' power down on , current 0.5mA , reference divider 128
I2cwbyte &B10100100                                           ' passive filter , VCO A
I2cwbyte &B00100111                                           ' main divider - high byte
I2cwbyte &B11010000                                           ' main divider - low byte
I2cstop                                                       ' stop
Return

Pll_sw2:
' Ustawienia wyjsc na standby'u
Reset Azw                                                     ' resetuj antyzwieche
Set Drv                                                       ' wylacz wzmacniacz w.cz.
Tmp = 0                                                       ' wpisz wartosc 0
Set Led                                                       ' zgas LED tx . wysoki stan
Reset Vco                                                     ' wylacz zasilanie VCO
Return