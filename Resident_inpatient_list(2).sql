select
  tbl_1.Ward,
  tbl_1.Room_Bed,
  tbl_1.SSN,
  tbl_1.Name,
  tbl_1.Admit_Date,
  tbl_2.cMort_1y,
  tbl_2.cMort_90d,
  tbl_2.pMort_1y,
  tbl_2.pMort_90d,
  tbl_2.Risk_Date

from
  (
    select
      location.locationname as Ward,
      roombed.roombed as Room_Bed,
      spatient.patientssn as SSN,
      spatient.patientname as Name,
      CONVERT(VARCHAR, inpatient.admitdatetime, 101) as Admit_Date
    from
      lsv.bisl_r1vx.ar3y_inpat_inpatient as inpatient
      inner join lsv.bisl_r1vx.ar3y_spatient_spatient as spatient
        on inpatient.patientsid = spatient.patientsid
      inner join lsv.dim.location as location
        on inpatient.admitwardlocationsid = location.wardlocationsid
      inner join lsv.dim.roombed as roombed
        on inpatient.admitroombedsid = roombed.roombedsid
    where
      inpatient.sta3n = '612'
      and inpatient.patientsid != '0'
      and spatient.deceasedflag != 'Y'
      and inpatient.admitdatetime > DATEADD(MONTH, -6, GETDATE())
      and inpatient.dischargedatetime is null
    group by
      spatient.patientssn,
      location.locationname,
      roombed.roombed,
      spatient.patientname,
      inpatient.admitdatetime
  ) as tbl_1
  LEFT JOIN 
  (
  select
    *
  from
    (
    select
      location.locationname as Ward,
      roombed.roombed as Room_Bed,
      spatient.patientssn as SSN,
      spatient.patientname as Name,
      CONVERT(VARCHAR, inpatient.admitdatetime, 101) as Admit_Date,
      ROUND(can_score.pmort_90d, 3, 0) as pMort_90d,
      ROUND(can_score.pmort_1y, 3, 0) as pMort_1y,
      can_score.cmort_90d as cMort_90d,
      can_score.cmort_1y as cMort_1y,
      CONVERT(VARCHAR, can_score.riskdate, 101) as Risk_Date,
      rn = ROW_NUMBER() OVER 
      (PARTITION BY spatient.patientssn ORDER BY can_score.riskdate DESC)
    from
      lsv.bisl_r1vx.ar3y_inpat_inpatient as inpatient
      inner join lsv.bisl_r1vx.ar3y_spatient_spatient as spatient
        on inpatient.patientsid = spatient.patientsid
      inner join lsv.dim.location as location
        on inpatient.admitwardlocationsid = location.wardlocationsid
      inner join lsv.dim.roombed as roombed
        on inpatient.admitroombedsid = roombed.roombedsid
      left join lsv.bisl_collab.canscore_history as can_score
        on spatient.patienticn = can_score.patienticn
    where
      inpatient.sta3n = '612'
      and inpatient.patientsid != '0'
      and spatient.deceasedflag != 'Y'
      and inpatient.admitdatetime > DATEADD(MONTH, -6, GETDATE())
      and inpatient.dischargedatetime is null
      and (
  	  can_score.riskdate >= DATEADD(MONTH, -12, GETDATE())
  	  OR can_score.riskdate IS NULL)
    group by
      spatient.patientssn,
      location.locationname,
      roombed.roombed,
      spatient.patientname,
      inpatient.admitdatetime,
      can_score.pmort_90d,
      can_score.pmort_1y,
      can_score.cmort_90d,
      can_score.cmort_1y,
      can_score.riskdate
  ) as x
  where
    rn = 1
  ) as tbl_2
  on tbl_1.ssn = tbl_2.ssn

order by
  tbl_1.Ward,
  tbl_1.Room_Bed