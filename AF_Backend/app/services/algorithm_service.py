import math
from decimal import Decimal

class AlgorithmService:
    @staticmethod
    def calculate_risk_factor_c(l1_risk: float, l2_risk: float, l1_weight: float = 0.7, l2_weight: float = 0.3) -> float:
        """
        Calculate Company Risk Factor (C).
        C = clamp(L1_wt * L1_risk + L2_wt * L2_risk, 0.30, 0.90)
        """
        c_unclamped = (l1_weight * l1_risk) + (l2_weight * l2_risk)
        return max(0.30, min(0.90, c_unclamped))

    @staticmethod
    def calculate_alpha(duration_months: int) -> float:
        """
        Calculate Weight Exponent (alpha).
        alpha = alpha_min + ((alpha_max - alpha_min) * (D_ref / (D + D_ref)))
        alpha_max = 2.0, alpha_min = 1.5, D_ref = 12
        """
        ALPHA_MAX = 2.0
        ALPHA_MIN = 1.5
        D_REF = 12
        return ALPHA_MIN + ((ALPHA_MAX - ALPHA_MIN) * (D_REF / (duration_months + D_REF)))

    @staticmethod
    def calculate_phase_count(risk_factor_c: float, funding_goal: float, duration_months: int, campaign_type_adj: int = -1) -> int:
        """
        Calculate Phase Count (P).
        NFRT = 3 + (D / (D + D_ref)) + (C / (C + C_ref)) + CT_phaseadj
        FRF = (F / F') * (P_max - NFRT)
        P = round(NFRT + FRF)
        """
        # Constants
        F_PRIME = 1000000.0  # Prototype ceiling
        P_MAX = 12
        D_REF = 12
        C_REF = 0.6  # Baseline risk (midpoint of 0.3-0.9)
        
        # Non-Financial Risk Term (NFRT)
        nfrt = 3 + (duration_months / (duration_months + D_REF)) + (risk_factor_c / (risk_factor_c + C_REF)) + campaign_type_adj
        
        # Financial Risk Factor (FRF)
        frf_max = P_MAX - nfrt
        f_ratio = min(1.0, funding_goal / F_PRIME)
        frf = f_ratio * frf_max
        
        p_raw = nfrt + frf
        p = round(p_raw)
        return max(3, min(12, int(p)))

    @staticmethod
    def calculate_milestone_weights(num_phases: int, alpha: float) -> list[float]:
        """
        Calculate weights for each phase based on alpha.
        Wi = i^alpha / sum(j^alpha)
        """
        weights = []
        total_weight = 0
        
        for i in range(1, num_phases + 1):
            w = math.pow(i, alpha)
            weights.append(w)
            total_weight += w
            
        # Normalize
        normalized_weights = [w / total_weight for w in weights]
        return normalized_weights

