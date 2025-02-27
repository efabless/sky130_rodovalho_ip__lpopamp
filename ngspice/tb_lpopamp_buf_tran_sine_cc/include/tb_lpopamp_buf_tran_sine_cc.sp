* num: #num corner: #corner vdd: #vdd temp: #temp

* Include SkyWater sky130 device models
.lib /usr/local/share/pdk/sky130A/libs.tech/combined/sky130.lib.spice #corner
.temp #temp

.include ../../netlists/lpopamp.cc.spice

* Simulation parameters
.param xavdd  = #vdd
.param xavss  = 0
.param xen    = 1
.param xvin   = {xavdd/2}
.param xvout  = {xavdd/2}

.param xavdd_ac = 0
.param xvin_ac  = 0
.param xvout_ac = 0

.param xibias = 10u

.param xcl    = 30p
.param xrl    = 5k

.param xvlo  = {10m}
.param xvhi  = {xavdd-10m}
.param xamp  = {xvlo-xvhi}
.param xfreq = {1k}
.param xper  = {1/xfreq}

* Design under test
*.subckt lpopamp im o ib vsub avss avdd enb en ip
Xdut out out ibias avss avss avdd enb en in lpopamp
v_avss GND avss xavss
v_avdd avdd avss dc {xavdd} ac {xavdd_ac} 
v_in in avss sine({xavdd/2} {xamp/2} {xfreq}) 
v_en en avss {xen*xavdd} 
v_enb enb avss {(1-xen)*xavdd} 
i_ibias avdd ibias {xen*xibias} 
CL out avss 'xcl' m=1 
v_out out_ avss dc {xvout} ac {xvout_ac} 
RL out out_ 'xrl' m=1 

* Simulation control
.option gmin   = 1e-10
.option abstol = 1e-10
.option reltol = 0.003
.option cshunt = 1e-15
.option method = Gear
.param xtstart = {xper}}
.param xtend   = {xtstart+4*xper}
.param xtstep  = {xper/100}
.tran {xtstep} {xtend} {xtstart}

.save v(in) v(out)
.option rshunt = 1e12
.control
  run
  plot in out

  set specwindow = blackman

  setplot tran1
  linearize v(out)
  fourier 1k v(out)

  let idx = 2
  let sum_mag_square = 0
  while idx < 10
    let mag = fourier11[1][idx]
    let sum_mag_square = sum_mag_square + mag * mag
    let idx = idx + 1
  end
  let root_sum_mag_square = sqrt(sum_mag_square)
  let thd = root_sum_mag_square / fourier11[1][1] * 100
  print thd

  echo "num,corner,vdd,temp,thd"       >  ./meas/tb_lpopamp_buf_tran_sine_cc.meas#num
  echo "#num,#corner,#vdd,#temp,$&thd" >> ./meas/tb_lpopamp_buf_tran_sine_cc.meas#num

  wrdata ./data/tb_lpopamp_buf_tran_sine_cc.dat#num tran1.v(in) tran1.v(out)

.endc

.GLOBAL GND 
.end 
