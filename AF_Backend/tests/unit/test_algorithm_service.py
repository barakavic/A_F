from app.services.algorithm_service import AlgorithmService

def test_risk_factor_c():
    # Test clamping
    assert AlgorithmService.calculate_risk_factor_c(0.1, 0.1) == 0.30 # Min clamp
    assert AlgorithmService.calculate_risk_factor_c(1.0, 1.0) == 0.90 # Max clamp
    assert AlgorithmService.calculate_risk_factor_c(0.5, 0.5) == 0.50 # Normal

def test_calculate_alpha():
    # D=0 -> 1.5 + 0.5*(12/12) = 2.0
    assert AlgorithmService.calculate_alpha(0) == 2.0
    # D=12 -> 1.5 + 0.5*(12/24) = 1.75
    assert AlgorithmService.calculate_alpha(12) == 1.75
    # D=huge -> 1.5
    assert AlgorithmService.calculate_alpha(1000) > 1.5 and AlgorithmService.calculate_alpha(1000) < 1.51

def test_calculate_phase_count():
    # Test with baseline values
    # C=0.6, D=12, Goal=0, CT_adj=-1
    # NFRT = 3 + 12/24 + 0.6/1.2 - 1 = 3 + 0.5 + 0.5 - 1 = 3
    # FRFMax = 12 - 3 = 9
    # FRF = 0 * 9 = 0
    # P = round(3 + 0) = 3
    assert AlgorithmService.calculate_phase_count(0.6, 0, 12, -1) == 3
    
    # Test with max goal
    # C=0.6, D=12, Goal=1M, CT_adj=-1
    # NFRT = 3
    # FRF = 1.0 * 9 = 9
    # P = round(3 + 9) = 12
    assert AlgorithmService.calculate_phase_count(0.6, 1000000, 12, -1) == 12

def test_milestone_weights():
    weights = AlgorithmService.calculate_milestone_weights(4, 1.0)
    assert len(weights) == 4
    assert abs(sum(weights) - 1.0) < 0.0001
    # Check increasing order
    assert weights[0] < weights[-1]

if __name__ == "__main__":
    test_risk_factor_c()
    print("test_risk_factor_c passed")
    test_calculate_alpha()
    print("test_calculate_alpha passed")
    test_calculate_phase_count()
    print("test_calculate_phase_count passed")
    test_milestone_weights()
    print("test_milestone_weights passed")
    print("All tests passed!")
