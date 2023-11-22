function Get-FFMC {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Temperature,
        [Parameter(Mandatory = $true)]
        [double]$RelativeHumidity,
        [Parameter(Mandatory = $true)]
        [double]$WindSpeed,
        [Parameter(Mandatory = $true)]
        [double]$Rainfall,
        [Parameter(Mandatory = $true)]
        [double]$PreviousFFMC
    )

    $T = $Temperature
    $H = $RelativeHumidity
    $W = $WindSpeed
    $ro = $Rainfall
    $Fo = $PreviousFFMC

    $mo = 147.2 * (101.0 - $Fo) / (59.5 + $Fo)
    if ($ro -gt 0.5) {
        $rf = $ro - 0.5
        if ($mo -le 150.0) {
            $mr = $mo + 42.5 * $rf * [Math]::Exp(-100.0 / (251.0 - $mo)) * (1.0 - [Math]::Exp(-6.93 / $rf))
        }
        else {
            $mr = $mo + 42.5 * $rf * [Math]::Exp(-100.0 / (251.0 - $mo)) * (1.0 - [Math]::Exp(-6.93 / $rf)) + (0.0015 * [Math]::Pow($mo - 150.0, 2.0) * [Math]::Pow($rf, 0.5))
        }
        if ($mr -gt 250.0) {
            $mr = 250.0
        }
        $mo = $mr
    }

    $Ed = 0.942 * [Math]::Pow($H, 0.679) + (11.0 * [Math]::Exp((($H - 100.0) / 10.0))) + 0.18 * (21.1 - $T) * (1.0 - [Math]::Exp(-0.115 * $H))
    if ($mo -gt $Ed) {
        $ko = 0.424 * (1.0 - [Math]::Pow($H / 100.0, 1.7)) + (0.0694 * [Math]::Pow($W, 0.5)) * (1.0 - [Math]::Pow($H / 100.0, 8.0))
        $kd = $ko * (0.581 * [Math]::Exp(0.0365 * $T))
        $m = $Ed + ($mo - $Ed) * [Math]::Pow(10.0, -$kd)
    } else {
        $Ew = 0.618 * [Math]::Pow($H, 0.753) + (10.0 * [Math]::Exp((($H - 100.0) / 10.0))) + 0.18 * (21.1 - $T) * (1.0 - [Math]::Exp(-0.115 * $H))
        if ($mo -lt $Ew) {
            $kl = 0.424 * (1.0 - [Math]::Pow((100.0 - $H) / 100.0, 1.7)) + (0.0694 * [Math]::Pow($W, 0.5)) * (1.0 - [Math]::Pow((100.0 - $H) / 100.0, 8.0))
            $kw = $kl * (0.581 * [Math]::Exp(0.0365 * $T))
            $m = $Ew - ($Ew - $mo) * [Math]::Pow(10.0, -$kw)
        } else {
            $m = $mo
        }
    }

    $F = (59.5 * (250.0 - $m)) / (147.2 + $m)
    if ($F -gt 101.0) {
        $F = 101.0
    }

    return $F
}

function Get-DMC {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Temperature,
        [Parameter(Mandatory = $true)]
        [double]$RelativeHumidity,
        [Parameter(Mandatory = $true)]
        [double]$Rainfall,
        [Parameter(Mandatory = $true)]
        [double]$PreviousDMC,
        [Parameter(Mandatory = $true)]
        [int]$Month
    )

    $T = $Temperature
    $H = $RelativeHumidity
    $ro = $Rainfall
    $Po = $PreviousDMC
    $I = $Month

    $Le = @(6.5, 7.5, 9.0, 12.8, 13.9, 13.9, 12.4, 10.9, 9.4, 8.0, 7.0, 6.0)
    if ($T -ge -1.1) {
        $K = 1.894 * ($T + 1.1) * (100.0 - $H) * $Le[$I - 1] * 0.0001
    } else {
        $K = 0.0
    }
    if ($ro -le 1.5) {
        $Pr = $Po
    } else {
        $re = 0.92 * $ro - 1.27
        $Mo = 20.0 + 280.0 / [Math]::Exp(0.023 * $Po)
        if ($Po -le 33.0) {
            $b = 100.0 / (0.5 + 0.3 * $Po)
        } else {
            if ($Po -le 65.0) {
                $b = 14.0 - 1.3 * [Math]::Log($Po)
            } else {
                $b = 6.2 * [Math]::Log($Po) - 17.2
            }
        }

        $Mr = $Mo + 1000.0 * $re / (48.77 + $b * $re)
        $Pr = 43.43 * (5.6348 - [Math]::Log($Mr - 20.0))
    }

    if ($Pr -lt 0.0) {
        $Pr = 0.0
    }

    $P = $Pr + $K
    if ($P -le 0.0) {
        $P = 0.0
    }
    return $P
}

function Get-DC {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Temperature,
        [Parameter(Mandatory = $true)]
        [double]$Rainfall,
        [Parameter(Mandatory = $true)]
        [double]$PreviousDC,
        [Parameter(Mandatory = $true)]
        [int]$Month
    )

    $T = $Temperature
    $ro = $Rainfall
    $Do = $PreviousDC
    $I = $Month

    $Lf = @(-1.6, -1.6, -1.6, 0.9, 3.8, 5.8, 6.4, 5.0, 2.4, 0.4, -1.6, -1.6);

    if ($ro -gt 2.8) {
        $rd = 0.83 * $ro - 1.27
        $Qo = 800.0 * [Math]::Exp(-$Do / 400.0)
        $Qr = $Qo + 3.937 * $rd
        $Dr = 400.0 * [Math]::Log(800.0 / $Qr)

        if ($Dr -gt 0.0) {
            $Do = $Dr
        } else {
            $Do = 0.0
        }
    }

    if ($T -gt -2.8) {
        $V = 0.36 * ($T + 2.8) + $Lf[$I - 1]
    } else {
        $V = $Lf[$I - 1]
    }

    if ($V -lt 0.0) {
        $V = 0.0
    }

    $D = $Do + (0.5 * $V)

    return $D
}

function Get-ISI {
    param (
        [Parameter(Mandatory = $true)]
        [double]$FFMC,
        [Parameter(Mandatory = $true)]
        [double]$WindSpeed
    )

    $F = $FFMC
    $W = $WindSpeed
    
    $fW = [Math]::Exp(0.05039 * $W)
    $m = 147.2 * (101.0 - $F) / (59.5 + $F)
    $fF = 91.9 * [Math]::Exp(-0.1386 * $m) * (1.0 + [Math]::Pow($m, 5.31) / 49300000.0)
    $R = 0.208 * $fW * $fF
    return $R
}

function Get-BUI {
    param (
        [Parameter(Mandatory = $true)]
        [double]$DMC,
        [Parameter(Mandatory = $true)]
        [double]$DC
    )
    
    $P = $DMC
    $D = $DC

    if ($P -le 0.4 * $D) {
        $U = 0.8 * $P * $D / ($P + 0.4 * $D)
    } else {
        $U = $P - (1.0 - 0.8 * $D / ($P + 0.4 * $D)) * (0.92 + [Math]::Pow(0.0114 * $P, 1.7))
    }
    if ($U -lt 0.0) {
        $U = 0.0
    }
    return $U
}

function Get-FWI {
    param (
        [Parameter(Mandatory = $true)]
        [double]$ISI,
        [Parameter(Mandatory = $true)]
        [double]$BUI
    )
    
    $R = $ISI
    $U = $BUI

    if ($U -le 80.0) {
        $fD = 0.626 * [Math]::Pow($U, 0.809) + 2.0
    } else {
        $fD = 1000.0 / (25.0 + 108.64 * [Math]::Exp(-0.023 * $U))
    }
    $B = 0.1 * $R * $fD
    if ($B -gt 1.0) {
        $S = [Math]::Exp(2.72 * ([Math]::Pow(0.434 * [Math]::Log($B), 0.647)))
    } else {
        $S = $B
    }

    return $S
}

function Get-Indicies {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Temperature,
        [Parameter(Mandatory = $true)]
        [double]$RelativeHumidity,
        [Parameter(Mandatory = $true)]
        [double]$WindSpeed,
        [Parameter(Mandatory = $true)]
        [double]$Rainfall,
        [Parameter(Mandatory = $true)]
        [int]$Month,
        [Parameter(Mandatory = $false)]
        [double]$PreviousFFMC = 85.0,
        [Parameter(Mandatory = $false)]
        [double]$PreviousDMC = 6.0,
        [Parameter(Mandatory = $false)]
        [double]$PreviousDC = 15.0
    )

    $mth = $Month
    $temp = $Temperature
    $rhum = $RelativeHumidity
    $wind = $WindSpeed
    $prcp = $Rainfall

    $ffmc0 = $PreviousFFMC
    $dmc0 = $PreviousDMC
    $dc0 = $PreviousDC

    if ($RelativeHumidity -gt 100.0) {
        $RelativeHumidity = 100.0
    }
    $ffmc = Get-FFMC -Temperature $temp -RelativeHumidity $rhum -WindSpeed $wind -Rainfall $prcp -PreviousFFMC $ffmc0
    $dmc = Get-DMC -Temperature $temp -RelativeHumidity $rhum -Rainfall $prcp -PreviousDMC $dmc0 -Month $mth
    $dc = Get-DC -Temperature $temp -Rainfall $prcp -PreviousDC $dc0 -Month $mth
    $isi = Get-ISI -FFMC $ffmc -WindSpeed $wind
    $bui = Get-BUI -DMC $dmc -DC $dc
    $fwi = Get-FWI -ISI $isi -BUI $bui

    return @{
        FFMC = $ffmc
        DMC = $dmc
        DC = $dc
        ISI = $isi
        BUI = $bui
        FWI = $fwi
    }
}

Export-ModuleMember -Function Get-FFMC, Get-DMC, Get-DC, Get-ISI, Get-BUI, Get-FWI, Get-Indicies
