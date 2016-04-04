require 'test_helper'

class LoadMonitorTest < MiniTest::Test

  def test_vendor
    assert_equal Usagewatch, ScaleWorkers::LoadMonitor.vendor
  end

  def test_cpu_load
    Usagewatch.expects(:uw_cpuused).once.returns(10.5)
    assert_equal 10.5, ScaleWorkers::LoadMonitor.cpu_load
  end

  def test_memory_load
    Usagewatch.expects(:uw_memused).once.returns(55)
    assert_equal 55, ScaleWorkers::LoadMonitor.memory_load
  end

  def test_can_increase_load_normal_load_case
    Usagewatch.expects(:uw_cpuused).times(5).returns(50).then.returns(51).then.returns(58).then.returns(53).then.returns(40)
    Usagewatch.expects(:uw_cpuused).times(5).returns(69).then.returns(60).then.returns(70).then.returns(50).then.returns(2)
    refute ScaleWorkers::LoadMonitor.can_increase_load?(55, 70)
  end

  def test_can_increase_load_high_load_case
    Usagewatch.expects(:uw_cpuused).returns(55).times(5).then.returns(51).then.returns(58).then.returns(53).then.returns(40)
    Usagewatch.expects(:uw_memused).returns(69).times(5).then.returns(60).then.returns(70).then.returns(80).then.returns(22)
    assert ScaleWorkers::LoadMonitor.can_increase_load?(55, 70)
  end

end
