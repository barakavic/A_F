from dataclasses import dataclass, field

@dataclass
class SimulationMetrics:
    tp: int = 0
    fp: int = 0
    fn: int = 0
    tn: int = 0

    @property
    def total(self):
        return self.tp + self.fp + self.fn + self.tn

    @property
    def accuracy(self):
        d = self.tp + self.tn + self.fp + self.fn
        return (self.tp + self.tn) / d if d > 0 else 0.0

    @property
    def precision(self):
        d = self.tp + self.fp
        return self.tp / d if d > 0 else 0.0

    @property
    def recall(self):
        d = self.tp + self.fn
        return self.tp / d if d > 0 else 0.0

    @property
    def f1_score(self):
        p, r = self.precision, self.recall
        return 2 * (p * r) / (p + r) if (p + r) > 0 else 0.0

class ValidationBrain:
    """Implements Section 3.6 evaluation logic."""
    def __init__(self):
        self.metrics = SimulationMetrics()
        self.audit_log = []

    def judge_decision(self, ground_truth: bool, system_decision: bool):
        """Compare ground truth vs system decision and update metrics."""
        if ground_truth and system_decision:
            self.metrics.tp += 1
            result = "TP (Correct Release)"
        elif not ground_truth and system_decision:
            self.metrics.fp += 1
            result = "FP (Invalid Release!)"
        elif ground_truth and not system_decision:
            self.metrics.fn += 1
            result = "FN (Missed Release)"
        else:
            self.metrics.tn += 1
            result = "TN (Correct Withhold)"
        
        entry = {
            "gt": ground_truth,
            "sys": system_decision,
            "result": result
        }
        self.audit_log.append(entry)
        return result

    def get_voting_pattern(self, scenario: str, total_voters: int, ratio: str = "75/25"):
        """Generate yes/no counts based on Section 3.6.1 scenarios."""
        pattern = {"yes": 0, "no": 0, "abstain": 0}
        
        if scenario == "normal":
            # Most vote correctly (assuming GT is True)
            pattern["yes"] = int(total_voters * 0.85)
            pattern["no"] = total_voters - pattern["yes"]
        
        elif scenario == "missing":
            # A subset fail to vote
            active = int(total_voters * 0.4) # Only 40% show up
            pattern["yes"] = int(active * 0.8)
            pattern["no"] = active - pattern["yes"]
            pattern["abstain"] = total_voters - active
            
        elif scenario == "mixed":
            # Threshold sensitivity (e.g., 60/40)
            try:
                y_perc = int(ratio.split('/')[0]) / 100
            except:
                y_perc = 0.6
            pattern["yes"] = int(total_voters * y_perc)
            pattern["no"] = total_voters - pattern["yes"]
            
        elif scenario == "incorrect":
            # Intentional incorrectness
            # If GT is True, they vote No. If GT is False, they vote Yes.
            pattern["yes"] = int(total_voters * 0.2) # Only 20% vote correctly
            pattern["no"] = total_voters - pattern["yes"]

        return pattern
