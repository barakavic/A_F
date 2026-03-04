import os

class WindowedInterface:
    """ASCII-based 'Windowed' Terminal Interface."""
    def __init__(self, coordinator):
        self.coord = coordinator
        self.term_width = 80

    def clear(self):
        os.system('clear' if os.name != 'nt' else 'cls')

    def draw_header(self):
        print("=" * self.term_width)
        print(f" ASCENT_FIN SIMULATION OVERSIGHT | Clock: {self.coord.virtual_clock.strftime('%Y-%m-%d %H:%M')}")
        print("=" * self.term_width)

    def draw_dashboard(self):
        print("\n[ DASHBOARD ]" + "-" * (self.term_width - 13))
        campaign = self.coord.active_campaign
        if campaign:
            print(f" PROJECT: {campaign['title']} ({campaign['id'][:8]}...)")
            print(f" PHASE:   {campaign['current_phase'] + 1} of {len(campaign['milestones'])}")
        else:
            print(" No active campaign. Use 'seed' to start.")
        
        users = self.coord.pop.users
        print(f" CROWD:   {len(users)} Synthetic Agents Active")
        print("-" * self.term_width)

    def draw_audit(self):
        print("\n[ SECTION 3.6 VALIDATION AUDIT ]" + "-" * (self.term_width - 32))
        m = self.coord.brain.metrics
        print(f" TP: {m.tp} | TN: {m.tn} | FP: {m.fp} | FN: {m.fn}")
        print(f" Accuracy: {m.accuracy:.2%} | Precision: {m.precision:.2%}")
        print(f" Recall:   {m.recall:.2%} | F1-Score:  {m.f1_score:.2%}")
        
        print("\n RECENT AUDIT LOG:")
        for log in self.coord.brain.audit_log[-3:]:
            gt_str = "VALID" if log['gt'] else "INVALID"
            print(f" -> Reality: {gt_str:<8} | Logic: {log['result']}")
        print("-" * self.term_width)

    def draw_help(self):
        print(f"\n LOG: {self.coord.status_message}")
        print("-" * self.term_width)
        print("\n COMMANDS: [seed] [pop N] [vote {scenario} {gt} {ratio}] [jump N] [drop] [exit]")
        print(" Scenario: normal | missing | mixed | incorrect")
        print(" Ground Truth (gt): y (valid) | n (invalid)")

    def refresh(self):
        self.clear()
        self.draw_header()
        self.draw_dashboard()
        self.draw_audit()
        self.draw_help()
