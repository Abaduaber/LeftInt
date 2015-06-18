{$I-} {$A+} {$R-} {$S-} {$Q-} {$G+} {$N+} {$D-} {$L-} {$Y-} {$X-}
Unit LTimer;

Interface
Function ReadTimer: LongInt;
Function ReadTimerChip: Word;
Function ReadOsc: LongInt;
Procedure DelayTicks(Ticks: LongInt);
Procedure Delay(MS: Word);

Implementation
Var
    Timer: LongInt Absolute $40:$6C;

Function ReadTimer: LongInt;
Begin
    ReadTimer:= Timer;
End;

Function ReadTimerChip: Word;
Var
    Frec: Word;
Begin
    Frec:= Port[$40];
    Frec:= Frec Or (Port[$40] Shl 8);
    ReadTimerChip:= Frec;
End;

Function ReadOsc: LongInt;
Begin
    ReadOsc:= ((ReadTimer And $7FFF) * $10000)
    Or (65535 - ReadTimerChip);
End;

Procedure DelayTicks(Ticks: LongInt);
Var
    FinishTime: LongInt;
Begin
    FinishTime:= ReadTimer + Ticks;
    Repeat Until ReadTimer >= FinishTime;
End;

Procedure Delay(MS: Word);
Const
    K = 1193180/1000;
Var
    FinishTime: LongInt;
Begin
    FinishTime:= ReadOsc + Trunc(MS * K);
    Repeat Until FinishTime <= ReadOsc;
End;

End.