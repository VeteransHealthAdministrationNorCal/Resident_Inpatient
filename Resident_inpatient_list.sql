SELECT DISTINCT
  Location.WardLocationName,
  RoomBed.RoomBed,
  SPatient.PatientSSN,
  SPatient.PatientName,
  Inpatient.AdmitDateTime,
  ACSC.cMort_1y,
  ACSC.cMort_90d,
  ACSC.pMort_1y,
  ACSC.pMort_90d,
  ACSC.Risk_Date

FROM
  LSV.BISL_R1VX.AR3Y_Inpat_Inpatient as Inpatient
  INNER JOIN LSV.Dim.WardLocation as Location
    ON Inpatient.AdmitWardLocationSID = Location.WardLocationSID
  INNER JOIN LSV.Dim.RoomBed as RoomBed
    ON Inpatient.AdmitRoomBedSID = RoomBed.RoomBedSID
  INNER JOIN LSV.BISL_R1VX.AR3Y_SPatient_SPatient as SPatient
    ON Inpatient.PatientSID = SPatient.PatientSID
  LEFT JOIN LSV.D05_VISN21Sites.MAC_ACSC as ACSC
    ON SPatient.PatientICN = ACSC.Patient_ICN

WHERE
  Inpatient.Sta3n = '612'
  AND Inpatient.PatientSID != '0'
  AND Inpatient.AdmitDateTime > CAST(DATEADD(MONTH, -6, GETDATE()) as date)
  AND Inpatient.DischargeDateTime IS NULL

ORDER BY
  Location.WardLocationName,
  RoomBed.RoomBed