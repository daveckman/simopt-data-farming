#!/usr/bin/env ruby -w

def exponentialRV(rate)		# generate an Exponential RV given the rate
  -Math.log(rand) / rate
end

if ARGV.length > 0
  init_red = ARGV.shift.to_i
  redkillbluerate = ARGV.shift.to_f
  init_blue = ARGV.shift.to_i
  bluekillredrate = ARGV.shift.to_f
else
  init_red = (STDERR.print \
     "Enter initial number of Red forces: "; gets).to_i
  redkillbluerate = (STDERR.print \
     "Enter per-capita rate at which Reds kill Blues (b): "; gets).to_f
  init_blue = (STDERR.print \
     "Enter initial number of Blue forces: "; gets).to_i
  bluekillredrate = (STDERR.print \
     "Enter per-capita rate at which Blues kill Reds (a): "; gets).to_f
end

t = 0.0
red = init_red
blue = init_blue
printf "InitialRed,RedKillBlueRate,InitialBlue,BlueKillRedRate,"
printf "FinalRed,FinalBlue,BattleDuration\n"

printf "%d,%6.5f,%d,%6.5f,", red, redkillbluerate, blue, bluekillredrate
while red > 0 && blue > 0 do	# As long as both sides have survivors
  # time of next fatal bullet
  t += exponentialRV((redkillbluerate*red) + (bluekillredrate*blue))
  pRedKill = (bluekillredrate*blue) /
             (bluekillredrate*blue + redkillbluerate*red)
  if rand <= pRedKill then		# determine who gets hit
    red -= 1
  else
    blue -= 1
  end
end
 
printf "%d,%d,%6.5f\n", red, blue, t
