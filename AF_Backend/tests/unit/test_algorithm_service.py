
from app.services.algorithm_service import AlgorithmService

def test_fti_calculation():
    # Test case 1: Max values -> FTI should be 1.0
    fti = AlgorithmService.calculate_fti(60, 20, 10, 5)
    assert abs(fti - 1.0) < 1e-9
    
    # Test case 2: Half values -> FTI should be 0.5
    fti = AlgorithmService.calculate_fti(30, 10, 5, 2.5)
    assert abs(fti - 0.5) < 1e-9
    
    # Test case 3: Zero values -> FTI should be 0.0
    fti = AlgorithmService.calculate_fti(0, 0, 0, 0)
    assert fti == 0.0
    
    # Test case 4: Outliers (Logarithmic fallback)
    # Tenure 240 (cap), S 1000 (cap), H 400 (cap), R 5
    # Should be close to 1.0 but maybe slightly different depending on log curve implementation details
    # Our implementation: min(1.0, ...) so it should be capped at 1.0
    fti = AlgorithmService.calculate_fti(240, 1000, 400, 5)
    assert abs(fti - 1.0) < 1e-9

def test_risk_factor_c():
    # Test clamping
    assert AlgorithmService.calculate_risk_factor_c(0.1, 0.1) == 0.30 # Min clamp
    assert AlgorithmService.calculate_risk_factor_c(1.0, 1.0) == 0.90 # Max clamp
    assert AlgorithmService.calculate_risk_factor_c(0.5, 0.5) == 0.50 # Normal

def test_alpha_calculation():
    # D = 12 -> alpha = 1.5 + 0.5(12/24) = 1.5 + 0.25 = 1.75
    assert AlgorithmService.calculate_alpha(12) == 1.75
    
    # D = 0 -> alpha = 1.5 + 0.5(1) = 2.0
    assert AlgorithmService.calculate_alpha(0) == 2.0

def test_phase_count():
    # Test bounds
    # High risk, low goal -> Low phases
    # C=0.3, Goal=1000
    # NFRT = 4.5 + 0.03(3.33) - 1 = 3.6
    # FRF ~ 0
    # P ~ 4
    p = AlgorithmService.calculate_phase_count(0.3, 1000)
    assert 3 <= p <= 12

def test_remedial_reserve():
    # Test bounds
    rm = AlgorithmService.calculate_remedial_reserve(1.0, 12)
    assert 0.05 <= rm <= 0.25

def test_milestone_weights():
    weights = AlgorithmService.calculate_milestone_weights(4, 1.0)
    assert len(weights) == 4
    assert abs(sum(weights) - 1.0) < 0.0001
    # Check increasing order
    assert weights[0] < weights[-1]

if __name__ == "__main__":
    test_fti_calculation()
    print("test_fti_calculation passed")
    test_risk_factor_c()
    print("test_risk_factor_c passed")
    test_alpha_calculation()
    print("test_alpha_calculation passed")
    test_phase_count()
    print("test_phase_count passed")
    test_remedial_reserve()
    print("test_remedial_reserve passed")
    test_milestone_weights()
    print("test_milestone_weights passed")
    print("All tests passed!")
