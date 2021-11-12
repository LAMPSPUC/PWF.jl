#################################################################
#                                                               #
# This file provides functions for interfacing with .pwf files  #
#                                                               #
#################################################################

# This parser was develop using ANAREDE v09 user manual

const _fban_1_dtypes = [("FROM BUS", Int64, 1:5), ("OPERATION", Int64, 7),
    ("TO BUS", Int64, 9:13), ("CIRCUIT", Int64, 15:16), ("CONTROL MODE", Char, 18),
    ("MINIMUM VOLTAGE", Float64, 20:23, 20), ("MAXIMUM VOLTAGE", Float64, 25:28, 25),
    ("CONTROLLED BUS", Int64, 30:34), ("INITIAL REACTIVE INJECTION", Float64, 36:41),
    ("CONTROL TYPE", Char, 43), ("ERASE DBAR", Char, 45), ("EXTREMITY", Int64, 47:51)]

const _fban_2_dtypes = [("GROUP", Int64, 1:2), ("OPERATION", Char, 5), ("STATUS", Char, 7),
    ("UNITIES", Int64, 9:11), ("OPERATING UNITIES", Int64, 13:15),
    ("REACTANCE", Float64, 17:22)]

const _dbsh_dtypes = Dict("first half" => _fban_1_dtypes, "first name" => "BUS AND VOLTAGE CONTROL",
    "second half" => _fban_2_dtypes, "second name" => "REACTORS AND CAPACITORS BANKS",
    "separator" => "FBAN", "subgroup" => "REACTANCE GROUPS")

const _fagr_1_dtypes = [("NUMBER", Int64, 1:3), ("DESCRIPTION", String, 5:40)]

const _fagr_2_dtypes = [("NUMBER", Int64, 1:3), ("OPERATION", Char, 5), ("DESCRIPTION", String, 7:42)]

const _dagr_dtypes = Dict("first half" => _fagr_1_dtypes, "first name" => "AGGREGATOR IDENTIFICATION",
    "second half" => _fagr_2_dtypes, "second name" => "AGGREGATOR OCCURENCES",
    "separator" => "FAGR", "subgroup" => "OCCURENCES")

const _divided_sections = Dict("DBSH" => _dbsh_dtypes,
                               "DAGR" => _dagr_dtypes)

"""
A list of data file sections in the order that they appear in a PWF file
"""
const _dbar_dtypes = [("NUMBER", Int64, 1:5), ("OPERATION", Int64, 6), 
    ("STATUS", Char, 7), ("TYPE", Int64, 8), ("BASE VOLTAGE GROUP", String, 9:10),
    ("NAME", String, 11:22), ("VOLTAGE LIMIT GROUP", String, 23:24),
    ("VOLTAGE", Float64, 25:28, 25), ("ANGLE", Float64, 29:32),
    ("ACTIVE GENERATION", Float64, 33:37), ("REACTIVE GENERATION", Float64, 38:42),
    ("MINIMUM REACTIVE GENERATION", Float64, 43:47),
    ("MAXIMUM REACTIVE GENERATION",Float64, 48:52), ("CONTROLLED BUS", Int64, 53:58),
    ("ACTIVE CHARGE", Float64, 59:63), ("REACTIVE CHARGE", Float64, 64:68),
    ("TOTAL REACTIVE POWER", Float64, 69:73), ("AREA", Int64, 74:76),
    ("CHARGE DEFINITION VOLTAGE", Float64, 77:80, 77), ("VISUALIZATION", Int64, 81),
    ("AGGREGATOR 1", Int64, 82:84), ("AGGREGATOR 2", Int64, 85:87),
    ("AGGREGATOR 3", Int64, 88:90), ("AGGREGATOR 4", Int64, 91:93),
    ("AGGREGATOR 5", Int64, 94:96), ("AGGREGATOR 6", Int64, 97:99),
    ("AGGREGATOR 7", Int64, 100:102), ("AGGREGATOR 8", Int64, 103:105),
    ("AGGREGATOR 9", Int64, 106:108), ("AGGREGATOR 10", Int64, 109:111)]

const _dlin_dtypes = [("FROM BUS", Int64, 1:5), ("OPENING FROM BUS", Char, 6),
    ("OPERATION", Int64, 8), ("OPENING TO BUS", Char, 10), ("TO BUS", Int64, 11:15),
    ("CIRCUIT", Int64, 16:17), ("STATUS", Char, 18), ("OWNER", Char, 19),
    ("RESISTANCE", Float64, 21:26, 24), ("REACTANCE", Float64, 27:32, 30),
    ("SHUNT SUSCEPTANCE", Float64, 33:38, 35), ("TAP", Float64, 39:43, 40),
    ("MINIMUM TAP", Float64, 44:48, 45), ("MAXIMUM TAP", Float64, 49:53, 50),
    ("LAG", Float64, 54:58, 56), ("CONTROLLED BUS", Int64, 59:64),
    ("NORMAL CAPACITY", Float64, 65:68), ("EMERGENCY CAPACITY", Float64, 69:72),
    ("NUMBER OF TAPS", Int64, 73:74), ("EQUIPAMENT CAPACITY", Float64, 75:78),
    ("AGGREGATOR 1", Int64, 79:81), ("AGGREGATOR 2", Int64, 82:84),
    ("AGGREGATOR 3", Int64, 85:87), ("AGGREGATOR 4", Int64, 88:90),
    ("AGGREGATOR 5", Int64, 91:93), ("AGGREGATOR 6", Int64, 94:96),
    ("AGGREGATOR 7", Int64, 97:99), ("AGGREGATOR 8", Int64, 100:102),
    ("AGGREGATOR 9", Int64, 103:105), ("AGGREGATOR 10", Int64, 106:108)]

const _dgbt_dtypes = [("GROUP", String, 1:2), ("VOLTAGE", Float64, 4:8)]

const _dglt_dtypes = [("GROUP", String, 1:2), ("LOWER BOUND", Float64, 4:8),
    ("UPPER BOUND", Float64, 10:14), ("LOWER EMERGENCY BOUND", Float64, 16:20),
    ("UPPER EMERGENCY BOUND", Float64, 22:26)]

const _dger_dtypes = [("NUMBER", Int, 1:5), ("OPERATION", Char, 7),
    ("MINIMUM ACTIVE GENERATION", Float64, 9:14),
    ("MAXIMUM ACTIVE GENERATION", Float64, 16:21),
    ("PARTICIPATION FACTOR", Float64, 23:27),
    ("REMOTE CONTROL PARTICIPATION FACTOR", Float64, 29:33),
    ("NOMINAL POWER FACTOR", Float64, 35:39), ("ARMATURE SERVICE FACTOR", Float64, 41:44),
    ("ROTOR SERVICE FACTOR", Float64, 46:49), ("CHARGE ANGLE", Float64, 51:54),
    ("MACHINE REACTANCE", Float64, 56:60), ("NOMINAL APPARENT POWER", Float64, 62:66)]

const _dshl_dtypes = [("FROM BUS", Int64, 1:5), ("OPERATION", Int64, 7),
    ("TO BUS", Int64, 10:14), ("CIRCUIT", Int64, 15:16), ("SHUNT FROM", Float64, 18:23),
    ("SHUNT TO", Float64, 24:29), ("STATUS FROM", String, 31:32), ("STATUS TO", String, 34:35)]

const _dcba_dtypes = [("NUMBER", Int64, 1:4), ("OPERATION", Int64, 6), ("TYPE", Int64, 8),
    ("POLARITY", String, 9), ("NAME", String, 10:21), ("VOLTAGE LIMIT GROUP", String, 22:23),
    ("VOLTAGE", Float64, 24:28), ("GROUND ELECTRODE", Float64, 67:71), ("DC LINK", Int64, 72:75)]

const _dcli_dtypes = [("FROM BUS", Int64, 1:4), ("OPERATION", Int64, 6), ("TO BUS", Int64, 9:12),
    ("CIRCUIT", Int64, 13:14), ("OWNER", Char, 16), ("RESISTANCE", Float64, 18:23),
    ("INDUCTANCE", Float64, 24:29), ("CAPACITY", Float64, 61:64)]

const _dcnv_dtypes = [("NUMBER", Int64, 1:4), ("OPERATION", Int64, 6), ("AC BUS", Int64, 8:12),
    ("DC BUS", Int64, 14:17), ("NEUTRAL BUS", Int64, 19:22), ("OPERATION MODE", Char, 24),
    ("BRIDGES", Int64, 26), ("CURRENT", Float64, 28:32), ("COMMUTATION REACTANCE", Float64, 34:38),
    ("SECONDARY VOLTAGE", Float64, 40:44), ("TRANSFORMER POWER", Float64, 46:50),
    ("REACTOR RESISTANCE", Float64, 52:56), ("REACTOR INDUCTANCE", Float64, 58:62),
    ("CAPACITANCE", Float64, 64:68), ("FREQUENCY", Float64, 70:71)]

const _dccv_dtypes = [("NUMBER", Int64, 1:4), ("OPERATION", Int64, 6), ("LOOSENESS", Char, 8),
    ("INVERTER CONTROL MODE", Char, 9), ("CONVERTER CONTROL TYPE", Char, 10),
    ("SPECIFIED VALUE", Float64, 12:16), ("CURRENT MARGIN", Float64,18:22),
    ("MAXIMUM OVERCURRENT", Float64, 24:28), ("CONVERTER ANGLE", Float64, 30:34),
    ("MINIMUM CONVERTER ANGLE", Float64, 36:40), ("MAXIMUM CONVERTER ANGLE", Float64, 42:46),
    ("MINIMUM TRANSFORMER TAP", Float64, 48:52), ("MAXIMUM TRANSFORMER TAP", Float64, 54:58),
    ("TRANSFORMER TAP NUMBER OF STEPS", Int64, 60:61),
    ("MINIMUM DC VOLTAGE FOR POWER CONTROL", Float64, 63:66, 63),
    ("TAP HI MVAR MODE", Float64, 68:72), ("TAP REDUCED VOLTAGE MODE", Float64, 74:78)]

const _delo_dtypes = [("NUMBER", Int64, 1:4), ("OPERATION", Int64, 6), ("VOLTAGE", Float64, 8:12),
    ("BASE", Float64, 14:18), ("NAME", String, 20:39), ("HI MVAR MODE", Char, 41), ("STATUS", Char, 43)]

const _dcer_dtypes = [("BUS", Int, 1:5), ("OPERATION", Char, 7), ("GROUP", Int64, 9:10),
    ("UNITIES", Int64, 12:13), ("CONTROLLED BUS", Int64, 15:19), ("INCLINATION", Float64, 21:26),
    ("REACTIVE GENERATION", Float64, 28:32), ("MINIMUM REACTIVE GENERATION", Float64, 33:37),
    ("MAXIMUM REACTIVE GENERATION", Float64, 38:42), ("CONTROL MODE", Char, 44), ("STATUS", Char, 46)]

const _dcsc_dtypes = [("FROM BUS", Int64, 1:5), ("OPERATION", Char, 7), ("TO BUS", Int64, 10:14),
    ("CIRCUIT", Int64, 15:16), ("STATUS", Char, 17), ("OWNER", Char, 18), ("BYPASS", Char, 19),
    ("MINIMUM VALUE", Float64, 26:31), ("MAXIMUM VALUE", Float64, 32:37), ("INITIAL VALUE", Float64, 38:43),
    ("CONTROL MODE", Char, 44), ("SPECIFIED VALUE", Float64, 46:51), ("MEASUREMENT EXTREMITY", Int64, 53:57),
    ("NUMBER OF STAGES", Int64, 58:60), ("NORMAL CAPACITY", Float64, 61:64),
    ("EMERGENCY CAPACITY", Float64, 65:68), ("EQUIPAMENT CAPACITY", Float64, 69:72), ("AGGREGATOR 1", Int64, 73:75),
    ("AGGREGATOR 2", Int64, 76:78), ("AGGREGATOR 3", Int64, 79:81), ("AGGREGATOR 4", Int64, 82:84),
    ("AGGREGATOR 5", Int64, 85:87), ("AGGREGATOR 6", Int64, 88:90), ("AGGREGATOR 7", Int64, 91:93), 
    ("AGGREGATOR 8", Int64, 94:96), ("AGGREGATOR 9", Int64, 97:99), ("AGGREGATOR 10", Int64, 100:102)]

const _dcar_dtypes = [("ELEMENT 1 TYPE", String, 1:4), ("ELEMENT 1 IDENTIFICATION", Int64, 6:10),
    ("CONDITION 1", Char, 12), ("ELEMENT 2 TYPE", String, 14:17), ("ELEMENT 2 IDENTIFICATION", Int64, 19:23),
    ("MAIN CONDITION", Char, 25), ("ELEMENT 3 TYPE", String, 27:30), ("ELEMENT 3 IDENTIFICATION", Int64, 32:36),
    ("CONDITION 2", Char, 38), ("ELEMENT 4 TYPE", String, 40:43), ("ELEMENT 4 IDENTIFICATION", Int64, 45:49),
    ("OPERATION", Char, 51), ("PARAMETER A", Float64, 53:55), ("PARAMETER B", Float64, 57:59),
    ("PARAMETER C", Float64, 61:63), ("PARAMETER D", Float64, 65:67), ("VOLTAGE", Float64, 69:73)]

const _dctr_dtypes = [("FROM BUS", Int64, 1:5), ("OPERATION", Char, 7), ("TO BUS", Int64, 9:13),
    ("CIRCUIT", Int64, 15:16), ("MINIMUM VOLTAGE", Float64, 18:21), ("MAXIMUM VOLTAGE", Float64, 23:26),
    ("BOUNDS CONTROL TYPE", Char, 28), ("CONTROL MODE", Char, 30), ("MINIMUM PHASE", Float64, 32:37),
    ("MAXIMUM PHASE", Float64, 39:44), ("CONTROL TYPE", Char, 46), ("SPECIFIED VALUE", Float64, 48:53),
    ("MEASUREMENT EXTREMITY", Int64, 55:59)]

const _dare_dtypes = [("NUMBER", Int64, 1:3), ("NET INTERCHANGE", Float64, 8:13),
    ("NAME", String, 19:54), ("MINIMUM INTERCHANGE", Float64, 56:61),
    ("MAXIMUM INTERCHANGE", Float64, 63:68)]

const _dtpf_circ_dtypes = [("FROM BUS 1", Int64, 1:5), ("TO BUS 1", Int64, 7:11),
    ("CIRCUIT 1", Int64, 13:14), ("FROM BUS 2", Int64, 16:20), ("TO BUS 2", Int64, 22:26),
    ("CIRCUIT 2", Int64, 28:29), ("FROM BUS 3", Int64, 31:35), ("TO BUS 3", Int64, 37:41),
    ("CIRCUIT 3", Int64, 43:44), ("FROM BUS 4", Int64, 46:50), ("TO BUS 4", Int64, 52:56),
    ("CIRCUIT 4", Int64, 58:59), ("FROM BUS 5", Int64, 61:65), ("TO BUS 5", Int64, 67:71),
    ("CIRCUIT 5", Int64, 73:74), ("OPERATION", Char, 76)]

const _dmte_dtypes = [("ELEMENT 1 TYPE", String, 1:4), ("ELEMENT 1 IDENTIFICATION", Int64, 6:10),
    ("CONDITION 1", Char, 12), ("ELEMENT 2 TYPE", String, 14:17), ("ELEMENT 2 IDENTIFICATION", Int64, 19:23),
    ("MAIN CONDITION", Char, 25), ("ELEMENT 3 TYPE", String, 27:30), ("ELEMENT 3 IDENTIFICATION", Int64, 32:36),
    ("CONDITION 2", Char, 38), ("ELEMENT 4 TYPE", String, 40:43), ("ELEMENT 4 IDENTIFICATION", Int64, 45:49),
    ("OPERATION", Char, 51), ("BOUNDARIES", Char, 53)]

const _dmfl_circ_dtypes = [("FROM BUS 1", Int64, 1:5), ("TO BUS 1", Int64, 7:11),
    ("CIRCUIT 1", Int64, 13:14), ("FROM BUS 2", Int64, 16:20), ("TO BUS 2", Int64, 22:26),
    ("CIRCUIT 2", Int64, 28:29), ("FROM BUS 3", Int64, 31:35), ("TO BUS 3", Int64, 37:41),
    ("CIRCUIT 3", Int64, 43:44), ("FROM BUS 4", Int64, 46:50), ("TO BUS 4", Int64, 52:56),
    ("CIRCUIT 4", Int64, 58:59), ("FROM BUS 5", Int64, 61:65), ("TO BUS 5", Int64, 67:71),
    ("CIRCUIT 5", Int64, 73:74), ("OPERATION", Char, 76)]

const _dcai_dtypes = [("BUS", Int64, 1:5), ("OPERATION", Char, 7), ("GROUP", Int64, 10:11),
    ("STATUS", Char, 13), ("UNITIES", Int64, 15:17), ("OPERATING UNITIES", Int64, 19:21),
    ("ACTIVE CHARGE", Float64, 23:27), ("REACTIVE CHARGE", Float64, 29:33),
    ("PARAMETER A", Float64, 35:37), ("PARAMETER B", Float64, 39:41),
    ("PARAMETER C", Float64, 43:45), ("PARAMETER D", Float64, 47:49), ("VOLTAGE", Float64, 51:55),
    ("VOLTAGE FOR CHARGE DEFINITION", Float64, 57:60)]

const _dgei_dtypes = [("BUS", Int64, 1:5), ("OPERATION", Char, 7), ("AUTOMATIC MODE", Char, 8),
    ("GROUP", Int64, 10:11), ("STATUS", Char, 13), ("UNITIES", Int64, 14:16),
    ("OPERATING UNITIES", Int64, 17:19), ("MINIMUM OPERATING UNITIES", Int64, 20:22),
    ("ACTIVE GENERATION", Float64, 23:27), ("REACTIVE GENERATION", Float64, 28:32),
    ("MINIMUM REACTIVE GENERATION", Float64, 33:37), ("MAXIMUM REACTIVE GENERATION", Float64, 38:42),
    ("ELEVATOR TRANSFORMER REACTANCE", Float64, 43:48), ("XD", Float64, 50:54, 53),
    ("XQ", Float64, 55:59, 58), ("XL", Float64, 60:64, 63), ("POWER FACTOR", Float64, 66:69, 67),
    ("APARENT POWER", Float64, 70:74, 72), ("MECHANICAL LIMIT", Float64, 75:79, 77)]

const _dmot_dtypes = [("BUS", Int64, 1:5), ("OPERATION", Char, 7), ("STATUS", Char, 8),
    ("GROUP", Int64, 10:11), ("SIGN", Char, 12), ("LOADING FACTOR", Float64, 13:15),
    ("UNITIES", Int64, 17:19), ("STATOR RESISTANCE", Float64, 21:25), ("STATOR REACTANCE", Float64, 27:31),
    ("MAGNETAZING REACTANCE", Float64, 33:37), ("ROTOR RESISTANCE", Float64, 39:43),
    ("ROTOR REACTANCE", Float64, 45:49), ("BASE POWER", Float64, 51:55),
    ("ENGINE TYPE", Int64, 57:59), ("ACTIVE CHARGE PORTION", Float64, 60:63),
    ("BASE POWER DEFINITION PERCENTAGE", Float64, 65:67)]

const _dcmt_dtypes = [("COMMENTS", String, 1:80)]

const _dinj_dtypes = [("NUMBER", Int64, 1:5), ("OPERATION", Char, 7),
    ("EQUIVALENT ACTIVE INJECITON", Float64, 9:15), ("EQUIVALENT REACTIVE INJECTION", Float64, 16:22),
    ("EQUIVALENT SHUNT", Float64, 23:29), ("EQUIVALENT PARTICIPATION FACTOR", Float64, 30:36)]

const _pwf_dtypes = Dict("DBAR" => _dbar_dtypes, "DLIN" => _dlin_dtypes, "DGBT" => _dgbt_dtypes,
    "DGLT" => _dglt_dtypes, "DGER" => _dger_dtypes, "DSHL" => _dshl_dtypes, "DCBA" => _dcba_dtypes, 
    "DCLI" => _dcli_dtypes, "DCNV" => _dcnv_dtypes, "DCCV" => _dccv_dtypes, "DELO" => _delo_dtypes, 
    "DCER" => _dcer_dtypes, "BUS AND VOLTAGE CONTROL" => _fban_1_dtypes, "REACTORS AND CAPACITORS BANKS" => _fban_2_dtypes,
    "DCSC" => _dcsc_dtypes, "DCAR" => _dcar_dtypes, "DCTR" => _dctr_dtypes, "DARE" => _dare_dtypes,
    "DTPF CIRC" => _dtpf_circ_dtypes, "DMTE" => _dmte_dtypes, "DMFL CIRC" => _dmfl_circ_dtypes,
    "AGGREGATOR IDENTIFICATION" => _fagr_1_dtypes, "AGGREGATOR OCCURENCES" => _fagr_2_dtypes,
    "DCAI" => _dcai_dtypes, "DGEI" => _dgei_dtypes, "DMOT" => _dmot_dtypes, "DCMT" => _dcmt_dtypes,
    "DINJ" => _dinj_dtypes)
    
const _mnemonic_dopc = (filter(x -> x[1]%7 == 1, [i:i+3 for i in 1:66]),
                        filter(x -> x%7 == 6, 1:69), Char)

const _mnemonic_dcte = (filter(x -> x[1]%12 == 1, [i:i+3 for i in 1:68]),
                        filter(x -> x[1]%12 == 6, [i:i+5 for i in 1:66]), Float64)

const _mnemonic_dbre = (filter(x -> x[1]%4 == 2, [i:i+1 for i in 1:78]),
                        filter(x -> x[1]%4 == 2, [i:i+1 for i in 1:78]), Int64)

"""
Sections which contains pairs that set values to some contants (DCTE)
and specify some execution control options (DOPC). 
"""
const _mnemonic_pairs = Dict("DOPC" =>  _mnemonic_dopc,
    "DCTE" => _mnemonic_dcte, "DBRE" => _mnemonic_dbre, "DOPC IMPR" => _mnemonic_dopc)

const _default_dbar = Dict("NUMBER" => nothing, "OPERATION" => 'A', "STATUS" => 'L',
    "TYPE" => 0, "BASE VOLTAGE GROUP" => " 0", "NAME" => nothing, "VOLTAGE LIMIT GROUP" => " 0",
    "VOLTAGE" => 1.0, "ANGLE" => 0.0, "ACTIVE GENERATION" => 0.0,
    "REACTIVE GENERATION" => 0.0, "MINIMUM REACTIVE GENERATION" => 0.0,
    "MAXIMUM REACTIVE GENERATION" => 0.0, "CONTROLLED BUS" => nothing,
    "ACTIVE CHARGE" => 0.0, "REACTIVE CHARGE" => 0.0, "TOTAL REACTIVE POWER" => 0.0,
    "AREA" => 1, "CHARGE DEFINITION VOLTAGE" => 1.0, "VISUALIZATION" => 0,
    "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing, "AGGREGATOR 3" => nothing, 
    "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing, "AGGREGATOR 6" => nothing, 
    "AGGREGATOR 7" => nothing, "AGGREGATOR 8" => nothing, "AGGREGATOR 9" => nothing, 
    "AGGREGATOR 10" => nothing)

const _default_dlin = Dict("FROM BUS" => nothing, "OPENING FROM BUS" => 'L',
    "OPERATION" => 'A', "OPENING TO BUS" => 'L', "TO BUS" => nothing, "CIRCUIT" => nothing,
    "STATUS" => 'L', "OWNER" => 'F', "RESISTANCE" => 0.0, "REACTANCE" => nothing,
    "SHUNT SUSCEPTANCE" => 0.0, "TAP" => 1.0, "MINIMUM TAP" => nothing,
    "MAXIMUM TAP" => nothing, "LAG" => 0.0, "CONTROLLED BUS" => nothing,
    "NORMAL CAPACITY" => Inf, "EMERGENCY CAPACITY" => Inf, "NUMBER OF TAPS" => 33,
    "EQUIPAMENT CAPACITY" => Inf, "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing,
    "AGGREGATOR 3" => nothing, "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing,
    "AGGREGATOR 6" => nothing, "AGGREGATOR 7" => nothing, "AGGREGATOR 8" => nothing,
    "AGGREGATOR 9" => nothing, "AGGREGATOR 10" => nothing)

const _default_dopc = Dict()

const _default_dcte = Dict("TEPA" => 0.1, "TEPR" => 0.1, "TLPR" => 0.1, "TLVC" => .5,
    "TLTC" => 0.01, "TETP" => 5.0, "TBPA" => 5.0, "TSFR" => 0.01, "TUDC" => 0.001,
    "TADC" => 0.01, "BASE" => 100.0, "DASE" => 100.0, "ZMAX" => 500.0, "ACIT" => 30,
    "LPIT" => 50, "LFLP" => 10, "LFIT" => 10, "DCIT" => 10, "VSIT" => 10, "LCRT" => 23,
    "LPRT" => 60, "LFCV" => 1, "TPST" => 0.2, "QLST" => 0.2, "EXST" => 0.4, "TLPP" => 1.0,
    "TSBZ" => 0.01, "TSBA" => 5.0, "PGER" => 30.0, "VDVN" => 40.0, "VDVM" => 200.0,
    "ASTP" => 0.05, "VSTP" => 5.0, "CSTP" => 5.0, "VFLD" => 70, "HIST" => 0, "ZMIN" => 0.001,
    "PDIT" => 10, "ICIT" => 50, "FDIV" => 2.0, "DMAX" => 5, "ICMN" => 0.05, "VART" => 5.0,
    "TSTP" => 33, "TSDC" => 0.02, "ASDC" => 1, "ICMV" => 0.5, "APAS" => 90, "CPAR" => 70,
    "VAVT" => 2.0, "VAVF" => 5.0, "VMVF" => 15.0, "VPVT" => 2.0, "VPVF" => 5.0,
    "VPMF" => 10.0, "VSVF" => 20.0, "VINF" => 1.0, "VSUP" => 1.0, "TLSI" => 0.0)

const _default_dger = Dict("NUMBER" => nothing, "OPERATION" => 'A',
    "MINIMUM ACTIVE GENERATION" => 0.0, "MAXIMUM ACTIVE GENERATION" => 99999.0,
    "PARTICIPATION FACTOR" => 0.0, "REMOTE CONTROL PARTICIPATION FACTOR" => 100.0,
    "NOMINAL POWER FACTOR" => nothing, "ARMATURE SERVICE FACTOR" => nothing,
    "ROTOR SERVICE FACTOR" => nothing, "CHARGE ANGLE" => nothing,
    "MACHINE REACTANCE" => nothing, "NOMINAL APPARENT POWER" => nothing)

const _default_dgbt = Dict("GROUP" => 0, "VOLTAGE" => 1.0)

const _default_dglt = Dict("GROUP" => nothing,  "LOWER BOUND" => 0.8, "UPPER BOUND" => 1.2,
    "LOWER EMERGENCY BOUND" => 0.8, "UPPER EMERGENCY BOUND" => 1.2)

const _default_dshl = Dict("FROM BUS" => nothing, "OPERATION" => 'A', "TO BUS" => nothing,
    "CIRCUIT" => nothing, "SHUNT FROM" => nothing, "SHUNT TO" => nothing,
    "STATUS FROM" => " L", "STATUS TO" => " L")

const _default_dcba = Dict("NUMBER" => nothing, "OPERATION" => 'A', "TYPE" => 0,
    "POLARITY" => nothing, "NAME" => nothing, "VOLTAGE LIMIT GROUP" => nothing,
    "VOLTAGE" => 0, "GROUND ELECTRODE" => 0.0, "DC LINK" => 1)

const _default_dcli = Dict("FROM BUS" => nothing, "OPERATION" => 'A', "TO BUS" => nothing,
    "CIRCUIT" => nothing, "OWNER" => nothing, "RESISTANCE" => nothing, "INDUCTANCE" => 0.0,
    "CAPACITY" => Inf)

const _default_dcnv = Dict("NUMBER" => nothing, "OPERATION" => 'A', "AC BUS" => nothing,
    "DC BUS" => nothing, "NEUTRAL BUS" => nothing, "OPERATION MODE" => nothing,
    "BRIDGES" => nothing, "CURRENT" => nothing, "COMMUTATION REACTANCE" => nothing,
    "SECONDARY VOLTAGE" => nothing, "TRANSFORMER POWER" => nothing, "REACTOR RESISTANCE" => 0.0,
    "REACTOR INDUCTANCE" => 0.0, "CAPACITANCE" => Inf, "FREQUENCY" => 60.0)

const _default_dccv = Dict("NUMBER" => nothing, "OPERATION" => 'A', "LOOSENESS" => 'N',
    "INVERTER CONTROL MODE" => nothing, "CONVERTER CONTROL TYPE" => nothing,
    "SPECIFIED VALUE" => nothing, "CURRENT MARGIN" => 10.0, "MAXIMUM OVERCURRENT" => 9999,
    "CONVERTER ANGLE" => 0.0, "MINIMUM CONVERTER ANGLE" => 0.0,
    "MAXIMUM CONVERTER ANGLE" => 0.0, "MINIMUM TRANSFORMER TAP" => nothing,
    "MAXIMUM TRANSFORMER TAP" => nothing, "TRANSFORMER TAP NUMBER OF STEPS" => Inf,
    "MINIMUM DC VOLTAGE FOR POWER CONTROL" => 0.0, "TAP HI MVAR MODE" => nothing,
    "TAP REDUCED VOLTAGE MODE" => 1.0)

const _default_delo = Dict("NUMBER" => nothing, "OPERATION" => 'A', "VOLTAGE" => nothing,
    "BASE" => nothing, "NAME" => nothing, "HI MVAR MODE" => 'N', "STATUS" => 'L')

const _default_dcer = Dict("BUS" => nothing, "OPERATION" => 'A', "GROUP" => nothing,
    "UNITIES" => 1, "CONTROLLED BUS" => nothing, "INCLINATION" => nothing,
    "REACTIVE GENERATION" => nothing, "MINIMUM REACTIVE GENERATION" => nothing,
    "MAXIMUM REACTIVE GENERATION" => nothing, "CONTROL MODE" => 'I', "STATUS" => 'L')

const _default_fban_2 = Dict("GROUP" => nothing, "OPERATION" => 'A', "STATUS" => 'L',
    "UNITIES" => 1, "OPERATING UNITIES" => nothing, "REACTANCE" => nothing)

const _default_fban_1 = Dict("FROM BUS" => nothing, "OPERATION" => 'A', "TO BUS" => nothing,
    "CIRCUIT" => 1, "CONTROL MODE" => 'C', "MINIMUM VOLTAGE" => nothing,
    "MAXIMUM VOLTAGE" => nothing, "CONTROLLED BUS" => nothing,
    "INITIAL REACTIVE INJECTION" => 0.0, "CONTROL TYPE" => 'C', "ERASE DBAR" => 'N',
    "EXTREMITY" => nothing, "REACTANCE GROUPS" => _default_fban_2)

const _default_fagr_2 = Dict("NUMBER" => nothing, "OPERATION" => 'A', "DESCRIPTION" => nothing)    

const _default_fagr_1 = Dict("NUMBER" => nothing, "DESCRIPTION" => nothing, "OCCURENCES" => _default_fagr_2)

const _default_dcsc = Dict("FROM BUS" => nothing, "OPERATION" => nothing, "TO BUS" => nothing,
    "CIRCUIT" => nothing, "STATUS" => 'L', "OWNER" => 'F', "BYPASS" => 'D',
    "MINIMUM VALUE" => -9999.0, "MAXIMUM VALUE" => 9999.0, "INITIAL VALUE" => nothing,
    "CONTROL MODE" => 'X', "SPECIFIED VALUE" => nothing, "MEASUREMENT EXTREMITY" => nothing,
    "NUMBER OF STAGES" => nothing, "NORMAL CAPACITY" => Inf, "EMERGENCY CAPACITY" => Inf,
    "EQUIPAMENT CAPACITY" => Inf, "AGGREGATOR 1" => nothing, "AGGREGATOR 2" => nothing,
    "AGGREGATOR 3" => nothing, "AGGREGATOR 4" => nothing, "AGGREGATOR 5" => nothing, 
    "AGGREGATOR 6" => nothing)

const _default_dcar = Dict("ELEMENT 1 TYPE" => nothing, "ELEMENT 1 IDENTIFICATION" => nothing,
    "CONDITION 1" => nothing, "ELEMENT 2 TYPE" => nothing, "ELEMENT 2 IDENTIFICATION" => nothing,
    "MAIN CONDITION" => nothing, "ELEMENT 3 TYPE" => nothing, "ELEMENT 3 IDENTIFICATION" => nothing,
    "CONDITION 2" => nothing, "ELEMENT 4 TYPE" => nothing, "ELEMENT 4 IDENTIFICATION" => nothing,
    "OPERATION" => 'A', "PARAMETER A" => nothing, "PARAMETER B" => nothing, "PARAMETER C" => nothing,
    "PARAMETER D" => nothing, "VOLTAGE" => nothing)

const _default_dctr = Dict("FROM BUS" => nothing, "OPERATION" => 'A', "TO BUS" => nothing,
    "CIRCUIT" => nothing, "MINIMUM VOLTAGE" => nothing, "MAXIMUM VOLTAGE" => nothing,
    "BOUNDS CONTROL TYPE" => 'C', "CONTROL MODE" => nothing, "MINIMUM PHASE" => nothing,
    "MAXIMUM PHASE" => nothing, "CONTROL TYPE" => 'F', "SPECIFIED VALUE" => nothing,
    "MEASUREMENT EXTREMITY" => nothing)

const _default_dare = Dict("NUMBER" => nothing, "NET INTERCHANGE" => 0.0, "NAME" => nothing,
    "MINIMUM INTERCHANGE" => 0.0, "MAXIMUM INTERCHANGE" => 0.0)

const _default_dtpf_circ = Dict("FROM BUS 1" => nothing, "TO BUS 1" => nothing, "CIRCUIT 1" => nothing,
    "FROM BUS 2" => nothing, "TO BUS 2" => nothing, "CIRCUIT 2" => nothing,
    "FROM BUS 3" => nothing, "TO BUS 3" => nothing, "CIRCUIT 3" => nothing,
    "FROM BUS 4" => nothing, "TO BUS 4" => nothing, "CIRCUIT 4" => nothing,
    "FROM BUS 5" => nothing, "TO BUS 5" => nothing, "CIRCUIT 5" => nothing, "OPERATION" => 'A')

const _default_dmte = Dict("ELEMENT 1 TYPE" => nothing, "ELEMENT 1 IDENTIFICATION" => nothing,
    "CONDITION 1" => nothing, "ELEMENT 2 TYPE" => nothing, "ELEMENT 2 IDENTIFICATION" => nothing,
    "MAIN CONDITION" => nothing, "ELEMENT 3 TYPE" => nothing, "ELEMENT 3 IDENTIFICATION" => nothing,
    "CONDITION 2" => nothing, "ELEMENT 4 TYPE" => nothing, "ELEMENT 4 IDENTIFICATION" => nothing,
    "OPERATION" => 'A', "BOUNDARIES" => 'T')

const _default_dmfl_circ = Dict("FROM BUS 1" => nothing, "TO BUS 1" => nothing, "CIRCUIT 1" => nothing,
    "FROM BUS 2" => nothing, "TO BUS 2" => nothing, "CIRCUIT 2" => nothing,
    "FROM BUS 3" => nothing, "TO BUS 3" => nothing, "CIRCUIT 3" => nothing,
    "FROM BUS 4" => nothing, "TO BUS 4" => nothing, "CIRCUIT 4" => nothing,
    "FROM BUS 5" => nothing, "TO BUS 5" => nothing, "CIRCUIT 5" => nothing, "OPERATION" => 'A')

const _default_dbre = Dict()

const _default_dcai = Dict("BUS" => nothing, "OPERATION" => 'A', "GROUP" => nothing,
    "STATUS" => 'L', "UNITIES" => 1, "OPERATING UNITIES" => 1, "ACTIVE CHARGE" => 0.0,
    "REACTIVE CHARGE" => 0.0, "PARAMETER A" => nothing, "PARAMETER B" => nothing,
    "PARAMETER C" => nothing, "PARAMETER D" => nothing, "VOLTAGE" => 0.7, "CHARGE DEFINITION VOLTAGE" => 1.0)

const _default_dgei = Dict("BUS" => nothing, "OPERATION" => 'A', "AUTOMATIC MODE" => 'N',
    "GROUP" => nothing, "STATUS" => 'L', "UNITIES" => 1, "OPERATING UNITIES" => 1,
    "MINIMUM OPERATING UNITIES" => 1, "ACTIVE GENERATION" => 0.0, "REACTIVE GENERATION" => 0.0,
    "MINIMUM REACTIVE GENERATION" => -9999.0, "MAXIMUM REACTIVE GENERATION" => 99999.0,
    "TRANSFORMER ELEVATOR REACTANCE" => nothing, "XD" => 0.0, "XQ" => 0.0, "XL" => 0.0,
    "POWER FACTOR" => 1.0, "APARENT POWER" => 99999.0, "MECHANICAL LIMIT" => 99999.0)

const _default_dmot = Dict("BUS" => nothing, "OPERATION" => 'A', "STATUS" => 'L',
    "GROUP" => nothing, "SIGN" => '+', "LOADING FACTOR" => 100.0, "UNITIES" => 1,
    "STATOR RESISTANCE" => nothing, "STATOR REACTANCE" => nothing, "MAGNETAZING REACTANCE" => nothing,
    "ROTOR RESISTANCE" => nothing, "ROTOR REACTANCE" => nothing, "BASE POWER" => nothing,
    "ENGINE TYPE" => nothing, "ACTIVE CHARGE PORTION" => nothing,
    "BASE POWER DEFINITION PERCENTAGE" => nothing)

const _default_dcmt = Dict("COMMENTS" => nothing)

const _default_dinj = Dict("NUMBER" => nothing, "OPERATION" => 'A',
    "EQUIVALENT ACTIVE INJECITON" => 0.0, "EQUIVALENT REACTIVE INJECITON" => 0.0,
    "EQUIVALENT SHUNT" => 0.0, "EQUIVALENT PARTICIPATION FACTOR" => 0.0)

const _default_titu = ""

const _default_name = ""

const _pwf_defaults = Dict("DBAR" => _default_dbar, "DLIN" => _default_dlin, "DCTE" => _default_dcte,
    "DOPC" => _default_dopc, "TITU" => _default_titu, "name" => _default_name, "DGER" => _default_dger,
    "DGBT" => _default_dgbt, "DGLT" => _default_dglt, "DSHL" => _default_dshl, "DCER" => _default_dcer,
    "DBSH" => _default_fban_1, "REACTANCE GROUPS" => _default_fban_2, "DCBA" => _default_dcba,
    "DCLI" => _default_dcli, "DCNV" => _default_dcnv, "DCCV" => _default_dccv, "DELO" => _default_delo,
    "DCSC" => _default_dcsc, "DCAR" => _default_dcar, "DCTR" => _default_dctr, "DARE" => _default_dare,
    "DTPF CIRC" => _default_dtpf_circ, "DMTE" => _default_dmte, "DMFL CIRC" => _default_dmfl_circ,
    "DBRE" => _default_dbre, "DOPC IMPR" => _default_dopc, "DAGR" => _default_fagr_1,
    "OCCURENCES" => _default_fagr_2, "DCAI" => _default_dcai, "DGEI" => _default_dgei,
    "DMOT" => _default_dmot, "DCMT" => _default_dcmt, "DINJ" => _default_dinj)


const title_identifier = "TITU"
const end_section_identifier = "99999"

function _remove_titles_from_file_lines(file_lines::Vector{String}, section_titles_idx::Vector{Int64})
    remove_titles_idx = vcat(section_titles_idx, section_titles_idx .+ 1)
    file_lines_without_titles_idx = setdiff(1:length(file_lines), remove_titles_idx)
    file_lines = file_lines[file_lines_without_titles_idx]
    return file_lines
end

"""
    _split_sections(io)

Internal function. Parses a pwf file into an array where each
element corresponds to a section, divided by the delimiter 99999.
"""
function _split_sections(io::IO)
    file_lines = readlines(io)
    filter!(x -> x != "" && x[1] != '(', file_lines) # Ignore commented and empty lines
    file_lines = replace.(file_lines, repeat([Char(65533) => ' '], length(file_lines)))
    sections = Vector{String}[]

    section_titles_idx = findall(line -> line == title_identifier, file_lines)
    if !isempty(section_titles_idx)
        last_section_title_idx = section_titles_idx[end]:section_titles_idx[end] + 1
        push!(sections, file_lines[last_section_title_idx])
    end

    file_lines = _remove_titles_from_file_lines(
        file_lines, section_titles_idx
    )

    section_delim = vcat(
        0, 
        findall(x -> x == end_section_identifier, file_lines)
    )

    num_sections = length(section_delim) - 1

    for i in 1:num_sections
        section_begin_idx = section_delim[i] + 1
        section_end_idx   = section_delim[i + 1] - 1

        # Account for multiple sections in the same pwf
        section_i = findall(x -> x[1] == file_lines[section_begin_idx], sections)
        @assert length(section_i) < 2
        if length(section_i) == 0
            push!(sections, file_lines[section_begin_idx:section_end_idx])
        else
            section_i = section_i[1]
            sections[section_i] = vcat(sections[section_i], file_lines[section_begin_idx + 1:section_end_idx])
        end
    end

    return sections
end

function _handle_implicit_decimal_point!(
    data::Dict, pwf_section::Vector, field::String, dtype, cols, element::String)
    
    field_idx     = findfirst(x -> x[1:3] == (field, dtype, cols), pwf_section)
    decimal_point = length(pwf_section[field_idx]) == 4 ? cols[end] - pwf_section[field_idx][4] : 0
    data[field]   = parse(dtype, element) / 10^decimal_point
end

"""
    _parse_line_element!(data, line, section)

Internal function. Parses a single line of data elements from a PWF file
and saves it into `data::Dict`.
"""
function _parse_line_element!(data::Dict{String, Any}, line::String, section::AbstractString)

    line_length = _pwf_dtypes[section][end][3][end]
    if length(line) < line_length
        extra_characters_needed = line_length - length(line)
        line = line * repeat(" ", extra_characters_needed)
    end

    for (field, dtype, cols) in _pwf_dtypes[section]
        element = line[cols]

        try
            if dtype != String && dtype != Char
                if dtype == Float64 && !('.' in element) # Implicit decimal point
                    _handle_implicit_decimal_point!(data, _pwf_dtypes[section], field, dtype, cols, element)
                else
                    data[field] = parse(dtype, element)
                end
            else
                data[field] = element
            end
        catch
            if !_needs_default(element)
                @warn "Could not parse $element to $dtype inside $section section, setting it as a String"
            end
            data[field] = element
        end
        
    end

end

function _parse_line_element!(data::Dict{String, Any}, lines::Vector{String}, section::AbstractString)

    mn_keys, mn_values, mn_type = _mnemonic_pairs[section]

    for line in lines
        for i in 1:length(mn_keys)
            k, v = mn_keys[i], mn_values[i]
            if v[end] <= length(line)

                if mn_type != String && mn_type != Char
                    try
                        data[line[k]] = parse(mn_type, line[v])
                    catch
                        if !_needs_default(line[v])
                            @warn "Could not parse $(line[v]) to $mn_type, setting it as a String"
                        end
                        !_needs_default(line[k]) ? data[line[k]] = line[v] : nothing
                    end
                else
                    !_needs_default(line[k]) ? data[line[k]] = line[v] : nothing
                end
                    
            end
        end
    end
end

"""
    _parse_section_element!(data, section_lines, section)
Internal function. Parses a section containing a system component.
Returns a Vector of Dict, where each entry corresponds to a single element.
"""
function _parse_section_element!(data::Dict{String, Any}, section_lines::Vector{String}, section::AbstractString, idx::Int64=1)

    if section == "DBAR"
        for line in section_lines[2:end]

            line_data = Dict{String, Any}()
            _parse_line_element!(line_data, line, section)

            bus_i = line_data["NUMBER"]
            data["$bus_i"] = line_data
        end

    else
        for line in section_lines[2:end]

            line_data = Dict{String, Any}()
            _parse_line_element!(line_data, line, section)

            data["$idx"] = line_data            
            idx += 1
        end
    end
end

function _parse_divided_section!(data::Dict{String, Any}, section_lines::Vector{String}, section::String)

    separator = _divided_sections[section]["separator"]
    sub_titles_idx = vcat(1, findall(x -> x == separator, section_lines))
    for (i, idx) in enumerate(sub_titles_idx)

        if idx != sub_titles_idx[end]
            next_idx = sub_titles_idx[i + 1]
            _parse_section_element!(data, section_lines[idx:idx + 1], _divided_sections[section]["first name"], i)

            rc = Dict{String, Any}()
            _parse_section_element!(rc, section_lines[idx + 1:next_idx - 1], _divided_sections[section]["second name"], i)

            group = _divided_sections[section]["subgroup"]
            data["$i"][group] = rc
        end

    end
end

"""
    _parse_section(data, section_lines)

Internal function. Receives an array of lines corresponding to a PWF section,
transforms it into a Dict and saves it into `data::Dict`.
"""
function _parse_section!(data::Dict{String, Any}, section_lines::Vector{String})
    section = section_lines[1]
    section_data = Dict{String, Any}()

    if section == title_identifier
        section_data = section_lines[end]

    elseif section in keys(_mnemonic_pairs)
        _parse_line_element!(section_data, section_lines[2:end], section)

    elseif section in keys(_pwf_dtypes)
        _parse_section_element!(section_data, section_lines, section)

    elseif section in keys(_divided_sections)
        _parse_divided_section!(section_data, section_lines, section)

    else
        @warn "Currently there is no support for $section parsing"
        section_data = nothing
    end
    data[section] = section_data
end

_needs_default(str::String) = unique(str) == [' ']
_needs_default(ch::Char) = ch == ' '

function _populate_defaults!(pwf_data::Dict{String, Any})

    @warn "Populating defaults"

    for (section, section_data) in pwf_data
        if !haskey(_pwf_defaults, section)
            @warn "Parser doesn't have default values for section $(section)."
        else
            if section in keys(_pwf_dtypes)
                _populate_section_defaults!(pwf_data, section, section_data)
            elseif section in keys(_mnemonic_pairs)
                _populate_mnemonic_defaults!(pwf_data, section, section_data)
            elseif section in keys(_divided_sections)
                _populate_section_defaults!(pwf_data, section, section_data)
            end
        end
    end

end

function _populate_section_defaults!(pwf_data::Dict{String, Any}, section::String, section_data::Dict{String, Any})
    component_defaults = _pwf_defaults[section]

    for (i, element) in section_data
        for (component, default) in component_defaults
            if haskey(element, component)
                component_value = element[component]
                if isa(component_value, String) || isa(component_value, Char)
                    if _needs_default(component_value)
                        pwf_data[section][i][component] = default
                        _handle_special_defaults!(pwf_data, section, i, component)
                    end
                elseif isa(component_value, Dict) || isa(component_value, Vector{Dict{String,Any}})
                    sub_data = pwf_data[section][i]
                    _populate_section_defaults!(sub_data, component, component_value)
                    pwf_data[section][i] = sub_data
                end
            else
                pwf_data[section][i][component] = default
                _handle_special_defaults!(pwf_data, section, i, component)
            end
        end
        _handle_transformer_default!(pwf_data, section, i)
    end
end

function _populate_mnemonic_defaults!(pwf_data::Dict{String, Any}, section::String, section_data::Dict{String, Any})
    component_defaults = _pwf_defaults[section]

    for (component, default) in component_defaults
        if haskey(section_data, component)
            component_value = section_data[component]
            if isa(component_value, String) || isa(component_value, Char)
                if _needs_default(component_value)
                    pwf_data[section][component] = default
                end
            end
        else
            pwf_data[section][component] = default
        end
    end
end

function _handle_special_defaults!(pwf_data::Dict{String, Any}, section::String, i::String, component::String)
    
    if section == "DBAR" && component == "MINIMUM REACTIVE GENERATION"
        bus_type = pwf_data[section][i]["TYPE"]
        if bus_type == 2
            pwf_data[section][i][component] = -9999.0
        end
    end
    if section == "DBAR" && component == "MAXIMUM REACTIVE GENERATION"
        bus_type = pwf_data[section][i]["TYPE"]
        if bus_type == 2
            pwf_data[section][i][component] = 99999.0
        end
    end

    if section == "DLIN" && component in ["TAP", "MINIMUM TAP", "MAXIMUM TAP"]
        # Count how many defaults were needed i.e. if there is any tap information in the PWF file
        pwf_data[section][i]["TRANSFORMER"] = get(pwf_data[section][i], "TRANSFORMER", 0) + 1
    end

    if section == "DBAR" && component == "CONTROLLED BUS"
        pwf_data[section][i][component] = pwf_data[section][i]["NUMBER"] # Default: the bus itself
    end
    if section == "DLIN" && component == "CONTROLLED BUS"
        pwf_data[section][i][component] = pwf_data[section][i]["FROM BUS"] # Default: the bus itself
    end

    if section == "DBSH" && component == "MINIMUM VOLTAGE"
        ctrl_bus = pwf_data[section][i]["CONTROLLED BUS"]
        group = pwf_data["DBAR"]["$ctrl_bus"]["VOLTAGE LIMIT GROUP"]
        group_idx = findfirst(x -> x["GROUP"] == group, pwf_data["DGLT"])
        pwf_data[section][i][component] = pwf_data["DGLT"][group_idx]["LOWER BOUND"]
    end
    if section == "DBSH" && component == "MAXIMUM VOLTAGE"
        ctrl_bus = pwf_data[section][i]["CONTROLLED BUS"]
        group = pwf_data["DBAR"]["$ctrl_bus"]["VOLTAGE LIMIT GROUP"]
        group_idx = findfirst(x -> x["GROUP"] == group, pwf_data["DGLT"])
        pwf_data[section][i][component] = pwf_data["DGLT"][group_idx]["UPPER BOUND"]
    end

    if section == "DCTR" && component in ["MINIMUM VOLTAGE", "MAXIMUM VOLTAGE"]
        pwf_data[section][i]["VOLTAGE CONTROL"] = false
    end
    if section == "DCTR" && component in ["MINIMUM PHASE", "MAXIMUM PHASE"]
        pwf_data[section][i]["PHASE CONTROL"] = false
    end
end

function _handle_transformer_default!(pwf_data::Dict{String, Any}, section::String, i::String)
    if section == "DLIN"
        if haskey(pwf_data[section][i], "TRANSFORMER") && pwf_data[section][i]["TRANSFORMER"] == 3
            pwf_data[section][i]["TRANSFORMER"] = false
        else
            pwf_data[section][i]["TRANSFORMER"] = true
        end
    end
end

"""
    _parse_pwf_data(data_io)

Internal function. Receives a pwf file as an IOStream and parses into a Dict.
"""
function _parse_pwf_data(data_io::IO)

    sections = _split_sections(data_io)
    pwf_data = Dict{String, Any}()
    pwf_data["name"] = match(r"^\<file\s[\/\\]*(?:.*[\/\\])*(.*)\.pwf\>$", lowercase(data_io.name)).captures[1]
    for section in sections
        _parse_section!(pwf_data, section)
    end
    _populate_defaults!(pwf_data)
    
    return pwf_data
end

function parse_pwf(filename::String)::Dict
    pwf_data = open(filename) do f
        parse_pwf(f)
    end

    return pwf_data
end

"""
    parse_pwf(io)

Reads PWF data in `io::IO`, returning a `Dict` of the data parsed into the
proper types.
"""
function parse_pwf(io::IO)
    # Open file, read it and parse to a Dict 
    pwf_data = _parse_pwf_data(io)
    return pwf_data
end
