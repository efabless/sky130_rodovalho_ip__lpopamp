* num: #num corner: #corner vdd: #vdd temp: #temp

* Include SkyWater sky130 device models
.lib /usr/local/share/pdk/sky130A/libs.tech/combined/sky130.lib.spice #corner
.temp #temp

.include ../../netlists/lpopamp.rcc.spice

* Simulation parameters
.param xavdd  = #vdd
.param xavss  = 0
.param xcm    = {#vdd/2}
.param xvin   = 0
.param xvout  = 0

.param xen =  1
.param xip =  0
.param xim =  1

.param xavdd_ac = 0
.param xvin_ac  = 1
.param xvout_ac = 0

.param xibias = 10u

.param xci    = 1T
.param xri    = 1T
.param xlf    = 1T
.param xrf    = 1f
.param xcl    = 30p
.param xrl    = 5k

* Design under test
*.subckt lpopamp im o ib vsub avss avdd enb en ip
Xdut im_ out ibias avss avss avdd enb en ip lpopamp
v_avss GND avss xavss
v_avdd avdd avss dc {xavdd} ac {xavdd_ac} 
v_en en avss {xen*xavdd} 
v_enb enb avss {(1-xen)*xavdd} 
i_ibias avdd ibias {xen*xibias} 
c_l out cm 'xcl' m=1 
c_i im_ im 'xci' m=1 
l_f out im_ 'xlf' m=1 
v_cm cm avss {xcm} 
v_im im avss dc {xavdd/2} 
v_ip ip avss dc {xavdd/2} 

* Simulation control
.save v(ip) v(out)
.save i(v_avdd)
.option rshunt = 1e12
.control
  * differential input
  alter v_ip   ac=0
  alter v_im   ac=1
  alter v_avdd ac=0

  op
  ac dec 10 10m 10G

  * common-mode input
  alter v_ip   ac=1
  alter v_im   ac=1
  alter v_avdd ac=0

  ac dec 10 10m 10G

  * power supply
  alter v_ip   ac=0
  alter v_im   ac=0
  alter v_avdd ac=1

  ac dec 10 10m 10G

  let vos  = op.v(out) - op.v(ip)
  let idd  = op.i(v_avdd)
  let av   = db(ac1.out)
  let ph   = cphase(ac1.out)*180/(4*atan(1))
  let cmrr = db(ac1.out/ac2.out)
  let psrr = db(ac1.out/ac3.out)

  meas ac av0p1hz find av at=0.1
  meas ac gbw when av=0
  meas ac pm180 when ph=-180
  meas ac pm find ph at=gbw
  meas ac gm find av at=pm180

  meas ac cmrr0p1hz find cmrr at=0.1
  meas ac psrr0p1hz find psrr at=0.1

  plot av cmrr psrr
  plot ph
  print idd vos

  echo "num,corner,vdd,temp,gbw,pm,av0p1hz,cmrr0p1hz,psrr0p1hz,idd,vos" > ./meas/tb_lpopamp_open_ac_rcc.meas#num
  echo "#num,#corner,#vdd,#temp,$&gbw,$&pm,$&av0p1hz,$&cmrr0p1hz,$&psrr0p1hz,$&idd,$&vos" >> ./meas/tb_lpopamp_open_ac_rcc.meas#num

  wrdata ./data/tb_lpopamp_open_ac_rcc_av.dat#num av
  wrdata ./data/tb_lpopamp_open_ac_rcc_ph.dat#num ph
  wrdata ./data/tb_lpopamp_open_ac_rcc_cmrr.dat#num cmrr
  wrdata ./data/tb_lpopamp_open_ac_rcc_psrr.dat#num psrr

.endc

.GLOBAL GND 
.end 
