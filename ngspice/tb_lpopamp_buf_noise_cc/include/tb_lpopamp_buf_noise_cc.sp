* num: #num corner: #corner vdd: #vdd temp: #temp

* Include SkyWater sky130 device models
.lib /usr/local/share/pdk/sky130A/libs.tech/combined/sky130.lib.spice #corner
.temp #temp

.include ../../netlists/lpopamp.cc.spice

* Simulation parameters
.param xavdd  = #vdd
.param xavss  = 0
.param xen    = 1
.param xvin   = {#vdd/2}
.param xvout  = {#vdd/2}

.param xavdd_ac = 0
.param xvin_ac  = 1
.param xvout_ac = 0

.param xibias = 10u

.param xcl    = 30p
.param xrl    = 1T

* Design under test
*.subckt lpopamp im o ib vsub avss avdd enb en ip
Xdut out out ibias avss avss avdd enb en in lpopamp
v_avss GND avss xavss
v_avdd avdd avss dc {xavdd} ac {xavdd_ac} 
v_in in avss dc {xvin} ac {xvin_ac} 
v_en en avss {xen*xavdd} 
v_enb enb avss {(1-xen)*xavdd} 
i_ibias avdd ibias {xen*xibias} 
CL out avss 'xcl' m=1 

* Simulation control
.option rshunt = 1e12
.control
  noise v(out) v_in dec 10 1 1G
  let onoise_10k   = noise1.onoise_spectrum[40]
  let onoise_total = noise2.onoise_total
  print onoise_10k onoise_total

  plot noise1.onoise_spectrum loglog
  
  echo "num,corner,vdd,temp,onoise_10k,onoise_total"         >  ./meas/tb_lpopamp_buf_noise_cc.meas#num
  echo "#num,#corner,#vdd,#temp,$&onoise_10k,$&onoise_total" >> ./meas/tb_lpopamp_buf_noise_cc.meas#num

  wrdata ./data/tb_lpopamp_buf_noise_cc_onoise.dat#num noise1.frequency noise1.onoise_spectrum

.endc

.GLOBAL GND 
.end 
