﻿-- Function: "WADE_R"."XML_ALLOCATION_DETAIL"(text, text, character varying, character varying, text)

-- DROP FUNCTION "WADE_R"."XML_ALLOCATION_DETAIL"(text, text, character varying, character varying, text);

CREATE OR REPLACE FUNCTION "WADE_R"."XML_ALLOCATION_DETAIL"(
    IN orgid text,
    IN reportid text,
    IN loctype character varying,
    IN loctxt character varying,
    IN datatype text,
    OUT tmp_output xml)
  RETURNS xml AS
$BODY$

BEGIN

IF datatype <> 'ALL' THEN

IF loctype='HUC' THEN

tmp_output:=(SELECT STRING_AGG
	(XMLELEMENT
		(name "WC:WaterAllocation", 
			(SELECT XMLFOREST
				("ALLOCATION_ID" AS "WC:AllocationIdentifier", 
				"ALLOCATION_OWNER" AS "WC:AllocationOwnerName", 
				"APPLICATION_DATE" AS "WC:ApplicationDate", 
				"PRIORITY_DATE" AS "WC:PriorityDate",
				"END_DATE" AS "WC:EndDate",
				C."VALUE" AS "WC:LegalStatusCode")
			), 
			(SELECT "WADE_R"."XML_D_ALLOCATION_LOCATION"
				(orgid,reportid,loctype,loctxt,A."ALLOCATION_ID")
			),	
			(SELECT CASE 

			WHEN datatype='ALLOCATION' THEN 
				(SELECT "WADE_R"."ALLOCATION_AMOUNT"
					(orgid,reportid,A."ALLOCATION_ID")
				) 
			WHEN datatype='DIVERSION' THEN XMLCONCAT
				(
					(SELECT "WADE_R"."ALLOCATION_AMOUNT"
						(orgid,reportid,A."ALLOCATION_ID")
					), 
					(SELECT "WADE_R"."XML_DIVERSION_DETAIL"
						(orgid,reportid,A."ALLOCATION_ID")
					)
				)
			WHEN datatype='USE' THEN 
				(SELECT "WADE_R"."XML_USE_DETAIL"
					(orgid,reportid,A."ALLOCATION_ID")
				)
			WHEN datatype='RETURN' THEN 
				(SELECT "WADE_R"."XML_RETURNFLOW_DETAIL"
					(orgid,reportid,A."ALLOCATION_ID")
				)END
			)
		)::text,''
	)
	
	FROM "WADE"."DETAIL_ALLOCATION" 
	A LEFT OUTER JOIN "WADE"."LU_LEGAL_STATUS" C ON (A."LEGAL_STATUS"=C."LU_SEQ_NO")
	WHERE EXISTS
	(SELECT B."ALLOCATION_ID" FROM "WADE_R"."DETAIL_LOCATION_MV" B
	WHERE A."ORGANIZATION_ID"=B."ORGANIZATION_ID" 
	AND A."REPORT_ID"=B."REPORT_ID" 
	AND A."ALLOCATION_ID"=B."ALLOCATION_ID"
	AND B."ORGANIZATION_ID"=orgid 
	AND B."REPORT_ID"=reportid 
	AND B."HUC" LIKE loctxt||'%' 
	AND B."DATATYPE"=datatype));

END IF;

IF loctype='COUNTY' THEN

	tmp_output:=(SELECT STRING_AGG(

	XMLELEMENT(name "WC:WaterAllocation", 

	(SELECT XMLFOREST("ALLOCATION_ID" AS "WC:AllocationIdentifier", "ALLOCATION_OWNER" AS "WC:AllocationOwnerName", "APPLICATION_DATE" AS "WC:ApplicationDate", 

	"PRIORITY_DATE" AS "WC:PriorityDate", "END_DATE" AS "WC:EndDate", C."VALUE" AS "WC:LegalStatusCode")), 
	(SELECT "WADE_R"."XML_D_ALLOCATION_LOCATION"(orgid,reportid,loctype,loctxt,A."ALLOCATION_ID")),	
	(SELECT CASE WHEN datatype='ALLOCATION' THEN (SELECT "WADE_R"."ALLOCATION_AMOUNT"(orgid,reportid,A."ALLOCATION_ID"))

		WHEN datatype='DIVERSION' THEN XMLCONCAT((SELECT "WADE_R"."ALLOCATION_AMOUNT"(orgid,reportid,A."ALLOCATION_ID")), (SELECT "WADE_R"."XML_DIVERSION_DETAIL"(orgid,reportid,A."ALLOCATION_ID"))) 

		WHEN datatype='USE' THEN (SELECT "WADE_R"."XML_USE_DETAIL"(orgid,reportid,A."ALLOCATION_ID"))

		WHEN datatype='RETURN' THEN (SELECT "WADE_R"."XML_RETURNFLOW_DETAIL"(orgid,reportid,A."ALLOCATION_ID"))

		END))::text,'')

	FROM "WADE"."DETAIL_ALLOCATION" A LEFT OUTER JOIN "WADE"."LU_LEGAL_STATUS" C ON (A."LEGAL_STATUS"=C."LU_SEQ_NO")

		WHERE EXISTS(SELECT B."ALLOCATION_ID" FROM "WADE_R"."DETAIL_LOCATION_MV" B

	WHERE A."ORGANIZATION_ID"=B."ORGANIZATION_ID" AND A."REPORT_ID"=B."REPORT_ID" AND A."ALLOCATION_ID"=B."ALLOCATION_ID"

	AND B."ORGANIZATION_ID"=orgid AND B."REPORT_ID"=reportid AND B."COUNTY_FIPS"=loctxt AND B."DATATYPE"=datatype));

END IF;

IF loctype='REPORTUNIT' THEN

	tmp_output:=(SELECT STRING_AGG(

	XMLELEMENT(name "WC:WaterAllocation", 

	(SELECT XMLFOREST("ALLOCATION_ID" AS "WC:AllocationIdentifier", "ALLOCATION_OWNER" AS "WC:AllocationOwnerName", "APPLICATION_DATE" AS "WC:ApplicationDate", 

	"PRIORITY_DATE" AS "WC:PriorityDate", "END_DATE" AS "WC:EndDate", C."VALUE" AS "WC:LegalStatusCode")), 
	(SELECT "WADE_R"."XML_D_ALLOCATION_LOCATION"(orgid,reportid,loctype,loctxt,A."ALLOCATION_ID")),	
	(SELECT CASE WHEN datatype='ALLOCATION' THEN (SELECT "WADE_R"."ALLOCATION_AMOUNT"(orgid,reportid,A."ALLOCATION_ID"))

		WHEN datatype='DIVERSION' THEN XMLCONCAT((SELECT "WADE_R"."ALLOCATION_AMOUNT"(orgid,reportid,A."ALLOCATION_ID")), (SELECT "WADE_R"."XML_DIVERSION_DETAIL"(orgid,reportid,A."ALLOCATION_ID"))) 

		WHEN datatype='USE' THEN (SELECT "WADE_R"."XML_USE_DETAIL"(orgid,reportid,A."ALLOCATION_ID"))

		WHEN datatype='RETURN' THEN (SELECT "WADE_R"."XML_RETURNFLOW_DETAIL"(orgid,reportid,A."ALLOCATION_ID"))

		END))::text,'')

	FROM "WADE"."DETAIL_ALLOCATION" A LEFT OUTER JOIN "WADE"."LU_LEGAL_STATUS" C ON (A."LEGAL_STATUS"=C."LU_SEQ_NO")

		WHERE EXISTS(SELECT B."ALLOCATION_ID" FROM "WADE_R"."DETAIL_LOCATION_MV" B

	WHERE A."ORGANIZATION_ID"=B."ORGANIZATION_ID" AND A."REPORT_ID"=B."REPORT_ID" AND A."ALLOCATION_ID"=B."ALLOCATION_ID"

	AND B."ORGANIZATION_ID"=orgid AND B."REPORT_ID"=reportid AND B."REPORTING_UNIT_ID"=loctxt AND B."DATATYPE"=datatype));

END IF;

ELSE

IF loctype='HUC' THEN

tmp_output:=(SELECT STRING_AGG
	(XMLELEMENT
		(name "WC:WaterAllocation", 
			(SELECT XMLFOREST
				("ALLOCATION_ID" AS "WC:AllocationIdentifier", 
				"ALLOCATION_OWNER" AS "WC:AllocationOwnerName", 
				"APPLICATION_DATE" AS "WC:ApplicationDate", 
				"PRIORITY_DATE" AS "WC:PriorityDate", 
				"END_DATE" AS "WC:EndDate", 
				C."VALUE" AS "WC:LegalStatusCode")
			), 
			(SELECT "WADE_R"."XML_D_ALLOCATION_LOCATION"
				(orgid,reportid,loctype,loctxt,A."ALLOCATION_ID")
			),	
			(SELECT "WADE_R"."ALLOCATION_AMOUNT"
				(orgid,reportid,A."ALLOCATION_ID")
			),
			(SELECT "WADE_R"."XML_DIVERSION_DETAIL"
				(orgid,reportid,A."ALLOCATION_ID")
			),
			(SELECT "WADE_R"."XML_USE_DETAIL"
				(orgid,reportid,A."ALLOCATION_ID")
			),
			(SELECT "WADE_R"."XML_RETURNFLOW_DETAIL"
				(orgid,reportid,A."ALLOCATION_ID")
			)
		)::text,''
	)

	FROM "WADE"."DETAIL_ALLOCATION" A LEFT OUTER JOIN "WADE"."LU_LEGAL_STATUS" C ON (A."LEGAL_STATUS"=C."LU_SEQ_NO")
	WHERE EXISTS(SELECT B."ALLOCATION_ID" FROM "WADE_R"."DETAIL_LOCATION_MV" B
	WHERE A."ORGANIZATION_ID"=B."ORGANIZATION_ID" AND A."REPORT_ID"=B."REPORT_ID" AND A."ALLOCATION_ID"=B."ALLOCATION_ID"
	AND B."ORGANIZATION_ID"=orgid AND B."REPORT_ID"=reportid AND B."HUC" LIKE loctxt||'%'));

END IF;

IF loctype='COUNTY' THEN

	tmp_output:=(SELECT STRING_AGG(

	XMLELEMENT(name "WC:WaterAllocation", 

	(SELECT XMLFOREST("ALLOCATION_ID" AS "WC:AllocationIdentifier", "ALLOCATION_OWNER" AS "WC:AllocationOwnerName", "APPLICATION_DATE" AS "WC:ApplicationDate", 

	"PRIORITY_DATE" AS "WC:PriorityDate", "END_DATE" AS "WC:EndDate", C."VALUE" AS "WC:LegalStatusCode")), 
	(SELECT "WADE_R"."XML_D_ALLOCATION_LOCATION"(orgid,reportid,loctype,loctxt,A."ALLOCATION_ID")),	
	(SELECT "WADE_R"."ALLOCATION_AMOUNT"(orgid,reportid,A."ALLOCATION_ID")),
	(SELECT "WADE_R"."XML_DIVERSION_DETAIL"(orgid,reportid,A."ALLOCATION_ID")),
	(SELECT "WADE_R"."XML_USE_DETAIL"(orgid,reportid,A."ALLOCATION_ID")),
	(SELECT "WADE_R"."XML_RETURNFLOW_DETAIL"(orgid,reportid,A."ALLOCATION_ID")))::text,'')
	FROM "WADE"."DETAIL_ALLOCATION" A LEFT OUTER JOIN "WADE"."LU_LEGAL_STATUS" C ON (A."LEGAL_STATUS"=C."LU_SEQ_NO")
	WHERE EXISTS(SELECT B."ALLOCATION_ID" FROM "WADE_R"."DETAIL_LOCATION_MV" B
	WHERE A."ORGANIZATION_ID"=B."ORGANIZATION_ID" AND A."REPORT_ID"=B."REPORT_ID" AND A."ALLOCATION_ID"=B."ALLOCATION_ID"
	AND B."ORGANIZATION_ID"=orgid AND B."REPORT_ID"=reportid AND B."COUNTY_FIPS"=loctxt));

END IF;

IF loctype='REPORTUNIT' THEN

	tmp_output:=(SELECT STRING_AGG(

	XMLELEMENT(name "WC:WaterAllocation", 

	(SELECT XMLFOREST("ALLOCATION_ID" AS "WC:AllocationIdentifier", "ALLOCATION_OWNER" AS "WC:AllocationOwnerName", "APPLICATION_DATE" AS "WC:ApplicationDate", 

	"PRIORITY_DATE" AS "WC:PriorityDate", "END_DATE" AS "WC:EndDate", C."VALUE" AS "WC:LegalStatusCode")), 
	(SELECT "WADE_R"."XML_D_ALLOCATION_LOCATION"(orgid,reportid,loctype,loctxt,A."ALLOCATION_ID")),	
	(SELECT "WADE_R"."ALLOCATION_AMOUNT"(orgid,reportid,A."ALLOCATION_ID")),
	(SELECT "WADE_R"."XML_DIVERSION_DETAIL"(orgid,reportid,A."ALLOCATION_ID")),
	(SELECT "WADE_R"."XML_USE_DETAIL"(orgid,reportid,A."ALLOCATION_ID")),
	(SELECT "WADE_R"."XML_RETURNFLOW_DETAIL"(orgid,reportid,A."ALLOCATION_ID")))::text,'')
	FROM "WADE"."DETAIL_ALLOCATION" A LEFT OUTER JOIN "WADE"."LU_LEGAL_STATUS" C ON (A."LEGAL_STATUS"=C."LU_SEQ_NO")
	WHERE EXISTS(SELECT B."ALLOCATION_ID" FROM "WADE_R"."DETAIL_LOCATION_MV" B
	WHERE A."ORGANIZATION_ID"=B."ORGANIZATION_ID" AND A."REPORT_ID"=B."REPORT_ID" AND A."ALLOCATION_ID"=B."ALLOCATION_ID"
	AND B."ORGANIZATION_ID"=orgid AND B."REPORT_ID"=reportid AND B."REPORTING_UNIT_ID"=loctxt));

END IF;

END IF;


tmp_output:='<WC:ReportDetails>'||tmp_output||'</WC:ReportDetails>';

RETURN;

		

END



  $BODY$
  LANGUAGE plpgsql STABLE
  COST 1000;
ALTER FUNCTION "WADE_R"."XML_ALLOCATION_DETAIL"(text, text, character varying, character varying, text)
  OWNER TO "WADE";
