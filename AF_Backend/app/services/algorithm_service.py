import math
from decimal import Decimal

class AlgorithmService:
    @staticmethod
    def calculate_fti(tenure_months: int, successful_campaigns: int, high_value_projects: int, rating: float) -> float:
        """
        Calculate Fundraiser Trust Index (FTI).
        FTI = min(1, 0.4(T/60) + 0.3(S/20) + 0.2(H/10) + 0.1(R/5))
        """
        # Normalization constants
        T_MAX, S_MAX, H_MAX, R_MAX = 60, 20, 10, 5
        
        # Logarithmic fallback caps
        T_CAP, S_CAP, H_CAP = 240, 1000, 400
        
        def normalize(value, normal_max, cap):
            if value <= normal_max:
                return value / normal_max
            else:
                # Logarithmic fallback: ln(1 + value) / ln(1 + cap)
                # Scaled to match the transition at normal_max? 
                # The doc says: "in the event of outliers the model switches to a logarithmic fallback"
                # Let's assume the formula replaces the linear term entirely or is applied to the excess?
                # Doc: f(x) = ln(1+x) / ln(1+cap_val)
                return math.log(1 + value) / math.log(1 + cap)

        t_norm = normalize(tenure_months, T_MAX, T_CAP)
        s_norm = normalize(successful_campaigns, S_MAX, S_CAP)
        h_norm = normalize(high_value_projects, H_MAX, H_CAP)
        r_norm = rating / R_MAX # Rating is usually bounded 0-5 anyway

        fti = (0.4 * t_norm) + (0.3 * s_norm) + (0.2 * h_norm) + (0.1 * r_norm)
        return min(1.0, fti)

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
        alpha = 1.5 + (0.5 * (12 / (D + 12)))
        """
        return 1.5 + (0.5 * (12 / (duration_months + 12)))

    @staticmethod
    def calculate_phase_count(risk_factor_c: float, funding_goal: float, campaign_type_adj: int = -1) -> int:
        """
        Calculate Phase Count (P).
        """
        # Constants
        F_PRIME = 1000000.0 # Prototype ceiling
        P_MAX = 12
        
        # Non-Financial Risk Term (NFRT)
        # NFRT = 3 + 1.5 + 0.03(1/C) + CT_phaseadj
        # Note: 3 + 1.5 = 4.5
        nfrt = 4.5 + (0.03 * (1 / risk_factor_c)) + campaign_type_adj
        
        # Financial Risk Factor (FRF)
        # FRF = (F / F') * (P_MAX - NFRT)
        # Ensure F doesn't exceed F' for this calc (or does it? Doc says "For smaller funding goals... scales down")
        # Doc says "When a campaign reaches a prototype ceiling of F'... contribution reaches its allowable maximum"
        # So we clamp F to F_PRIME for the ratio? Or just use raw ratio?
        # "For smaller funding goals... scales down". "never exceeds maximum number of 12".
        # Let's assume F is capped at F_PRIME for the calculation if it's larger, or the ratio is capped at 1.
        f_ratio = min(1.0, funding_goal / F_PRIME)
        frf = f_ratio * (P_MAX - nfrt)
        
        p_raw = nfrt + frf
        p = round(p_raw)
        return max(3, min(12, int(p)))

    @staticmethod
    def calculate_remedial_reserve(fti: float, duration_months: int, campaign_type_risk_adj: float = 0.03) -> float:
        """
        Calculate Final Remedial Reserve (Rm).
        Rm = clamp(Rm0 + CT_riskadj + 0.02(D/Dref), 0.05, 0.25)
        """
        D_REF = 12
        
        # Base Remedial Reserve
        # Rm0 = 0.15 - 0.05(FTI)
        rm0 = 0.15 - (0.05 * fti)
        
        # Final Rm
        rm = rm0 + campaign_type_risk_adj + (0.02 * (duration_months / D_REF))
        return max(0.05, min(0.25, rm))

    @staticmethod
    def calculate_milestone_weights(num_phases: int, alpha: float) -> list[float]:
        """
        Calculate weights for each phase based on alpha.
        Using an exponential growth function to ensure later phases have higher weights.
        Wi proportional to e^(alpha * i_normalized)
        """
        weights = []
        total_weight = 0
        
        for i in range(1, num_phases + 1):
            # Normalize i to 0..1 range or just use i?
            # If we use i directly with alpha ~1.5-2.0, e^2 is ~7, e^12 is huge.
            # Maybe the formula intended something else?
            # "steeper curve... funds are released in higher increments in the later phases"
            # Let's use a simple power law or exponential based on phase index.
            # Let's try: w_i = e^(alpha * (i / P)) - 1 ?
            # Or just w_i = i^alpha ?
            # Given "Exponential decay of alpha", and "steeper curves for short projects",
            # If alpha is high, we want more skew towards the end.
            # i^alpha works: 
            # if alpha=2, 1, 4, 9...
            # if alpha=1, 1, 2, 3... (flatter)
            # This seems to fit "steeper curve" description.
            
            w = math.pow(i, alpha)
            weights.append(w)
            total_weight += w
            
        # Normalize
        normalized_weights = [w / total_weight for w in weights]
        return normalized_weights
