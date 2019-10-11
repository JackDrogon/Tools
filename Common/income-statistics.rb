#!/usr/bin/env ruby
# -*- coding:utf-8 -*-

def calc(single_bill, rate, turns, bill_up)
  sum = 0
  1.upto(turns) do |turn|
    sum = (sum+single_bill)*(1+rate)
    single_bill *= (turn % 12 == 1 ? 1.1 : 1) if bill_up
  end
  sum
end

# define_singleton_method
def compare(single_bill, rate, turns, bill_up = true)
  final = calc(single_bill, rate, turns, bill_up)
  origin = calc(single_bill, 0, turns, bill_up)
  puts "=== BillUp: #{bill_up}, SingleBill: #{single_bill}, Rate: #{rate}, Years: #{turns/12}
    Origin: #{origin}, Final: #{final}, FinalRate: #{final/origin - 1}"
    # Origin: #{single_bill*turns}, Final: #{final}, FinalRate: #{final/single_bill/turns - 1}"
  # puts  single_bill*turns, calc(2000, 0.008, 30*12)
end

# single_bill = 2000
# turns = 30 * 12 # 30年

# compare(400, 0.008, 30 * 12)
# compare(400, 0.008, 30 * 12, false)
compare(10000, 1.2 ** (1.0/12) - 1, 35 * 12, false)
compare(10000, 0.016, 35 * 12, false)
# compare(400, 0.008, 25 * 12)
# compare(400, 0.008, 25 * 12, false)
# compare(1000, 20.0/12/100, 10 * 12)
