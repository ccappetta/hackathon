create schema public;

comment on schema public is 'standard public schema';

alter schema public owner to ccsandbox;

create table if not exists judgement
(
	judgement_id bigserial not null
		constraint judgement_pkey
			primary key,
	judge_name varchar,
	submission_team varchar,
	overall_score integer,
	innovation_score integer,
	technical_competency_score integer,
	business_value_score integer,
	useability_score integer,
	overall_comments varchar,
	flow_url varchar,
	import_token varchar,
	submission_id integer,
	innovation_comments varchar,
	technical_comments varchar,
	business_value_comments varchar,
	useability_comments varchar,
	video varchar,
	grand_total integer,
	submitter_comments varchar,
	app_name varchar,
	tenant varchar,
	completeness_score integer,
	completeness_comments varchar,
	presentation_score integer,
	presentation_comments varchar,
	xfactor_score integer,
	xfactor_comments varchar
);

alter table judgement owner to ccsandbox;

create table if not exists submissions
(
	submission_id bigserial not null
		constraint submissions_pkey
			primary key,
	submitter varchar,
	flow_url varchar,
	import_token varchar,
	video varchar,
	submitter_comments varchar,
	app_name varchar,
	tenant varchar
);

alter table submissions owner to ccsandbox;

create or replace view v_team_summaries(submission_team, average_biz_value_score, average_presentation_score, average_ux_score, average_completeness_score, average_technical_score, average_innovation_score, average_overall_score, average_xfactor_score, total_average_score, total_total_score, judgements_submitted) as
SELECT judgement.submission_team,
       to_char(avg(judgement.business_value_score), 'FM999999999.0'::text)       AS average_biz_value_score,
       to_char(avg(judgement.presentation_score), 'FM999999999.0'::text)         AS average_presentation_score,
       to_char(avg(judgement.useability_score), 'FM999999999.0'::text)           AS average_ux_score,
       to_char(avg(judgement.completeness_score), 'FM999999999.0'::text)         AS average_completeness_score,
       to_char(avg(judgement.technical_competency_score), 'FM999999999.0'::text) AS average_technical_score,
       to_char(avg(judgement.innovation_score), 'FM999999999.0'::text)           AS average_innovation_score,
       to_char(avg(judgement.overall_score), 'FM999999999.0'::text)              AS average_overall_score,
       to_char(avg(judgement.xfactor_score), 'FM999999999.0'::text)              AS average_xfactor_score,
       sum(COALESCE(judgement.business_value_score, 0) + COALESCE(judgement.presentation_score, 0) +
           COALESCE(judgement.useability_score, 0) + COALESCE(judgement.completeness_score, 0) +
           COALESCE(judgement.technical_competency_score, 0) + COALESCE(judgement.innovation_score, 0) +
           COALESCE(judgement.overall_score, 0)) / count(*)                      AS total_average_score,
       sum(COALESCE(judgement.business_value_score, 0) + COALESCE(judgement.presentation_score, 0) +
           COALESCE(judgement.useability_score, 0) + COALESCE(judgement.completeness_score, 0) +
           COALESCE(judgement.technical_competency_score, 0) + COALESCE(judgement.innovation_score, 0) +
           COALESCE(judgement.overall_score, 0))                                 AS total_total_score,
       count(*)                                                                  AS judgements_submitted
FROM judgement
GROUP BY judgement.submission_team;

alter table v_team_summaries owner to ccsandbox;

create or replace view v_judge_team_total_score(judge_name, submission_team, total_score, innovation_score, technical_competency_score, business_value_score, completeness_score, presentation_score, xfactor_score, overall_score, useability_score) as
SELECT judgement.judge_name,
       judgement.submission_team,
       judgement.overall_score + judgement.innovation_score + judgement.technical_competency_score +
       judgement.business_value_score + judgement.completeness_score + judgement.presentation_score +
       judgement.xfactor_score + judgement.useability_score AS total_score,
       judgement.innovation_score,
       judgement.technical_competency_score,
       judgement.business_value_score,
       judgement.completeness_score,
       judgement.presentation_score,
       judgement.xfactor_score,
       judgement.overall_score,
       judgement.useability_score
FROM judgement
ORDER BY (judgement.overall_score + judgement.innovation_score + judgement.technical_competency_score +
          judgement.business_value_score + judgement.completeness_score + judgement.presentation_score +
          judgement.xfactor_score + judgement.useability_score) DESC;

alter table v_judge_team_total_score owner to ccsandbox;

create or replace view v_judge_team_total_score_ranked(judge_name, submission_team, total_score, rank) as
SELECT v_judge_team_total_score.judge_name,
       v_judge_team_total_score.submission_team,
       v_judge_team_total_score.total_score,
       rank()
       OVER (PARTITION BY v_judge_team_total_score.judge_name ORDER BY v_judge_team_total_score.total_score DESC) AS rank
FROM v_judge_team_total_score;

alter table v_judge_team_total_score_ranked owner to ccsandbox;

create or replace view v_top_teams_by_number_top_judge_votes(submission_team, count) as
SELECT v_judge_team_total_score_ranked.submission_team,
       count(*) AS count
FROM v_judge_team_total_score_ranked
WHERE v_judge_team_total_score_ranked.rank = 1
GROUP BY v_judge_team_total_score_ranked.submission_team;

alter table v_top_teams_by_number_top_judge_votes owner to ccsandbox;

create or replace view v_top_teams_by_number_top_judge_votes_innovation(submission_team, num_top_judge_votes_innovation) as
SELECT temp1.submission_team,
       count(temp1.*) AS num_top_judge_votes_innovation
FROM (SELECT v_judge_team_total_score.judge_name,
             v_judge_team_total_score.submission_team,
             v_judge_team_total_score.innovation_score,
             rank()
             OVER (PARTITION BY v_judge_team_total_score.judge_name ORDER BY v_judge_team_total_score.innovation_score DESC) AS rank
      FROM v_judge_team_total_score) temp1
WHERE temp1.rank = 1
GROUP BY temp1.submission_team;

alter table v_top_teams_by_number_top_judge_votes_innovation owner to ccsandbox;

create or replace view v_top_teams_by_number_top_judge_votes_technical_competency(submission_team, num_top_judge_votes_technical_competency) as
SELECT temp1.submission_team,
       count(temp1.*) AS num_top_judge_votes_technical_competency
FROM (SELECT v_judge_team_total_score.judge_name,
             v_judge_team_total_score.submission_team,
             v_judge_team_total_score.technical_competency_score,
             rank()
             OVER (PARTITION BY v_judge_team_total_score.judge_name ORDER BY v_judge_team_total_score.technical_competency_score DESC) AS rank
      FROM v_judge_team_total_score) temp1
WHERE temp1.rank = 1
GROUP BY temp1.submission_team;

alter table v_top_teams_by_number_top_judge_votes_technical_competency owner to ccsandbox;

create or replace view v_top_teams_by_number_top_judge_votes_business_value(submission_team, num_top_judge_votes_business_value) as
SELECT temp1.submission_team,
       count(temp1.*) AS num_top_judge_votes_business_value
FROM (SELECT v_judge_team_total_score.judge_name,
             v_judge_team_total_score.submission_team,
             v_judge_team_total_score.business_value_score,
             rank()
             OVER (PARTITION BY v_judge_team_total_score.judge_name ORDER BY v_judge_team_total_score.business_value_score DESC) AS rank
      FROM v_judge_team_total_score) temp1
WHERE temp1.rank = 1
GROUP BY temp1.submission_team;

alter table v_top_teams_by_number_top_judge_votes_business_value owner to ccsandbox;

create or replace view v_top_teams_by_number_top_judge_votes_completeness(submission_team, num_top_judge_votes_completeness) as
SELECT temp1.submission_team,
       count(temp1.*) AS num_top_judge_votes_completeness
FROM (SELECT v_judge_team_total_score.judge_name,
             v_judge_team_total_score.submission_team,
             v_judge_team_total_score.completeness_score,
             rank()
             OVER (PARTITION BY v_judge_team_total_score.judge_name ORDER BY v_judge_team_total_score.completeness_score DESC) AS rank
      FROM v_judge_team_total_score) temp1
WHERE temp1.rank = 1
GROUP BY temp1.submission_team;

alter table v_top_teams_by_number_top_judge_votes_completeness owner to ccsandbox;

create or replace view v_top_teams_by_number_top_judge_votes_presentation(submission_team, num_top_judge_votes_presentation) as
SELECT temp1.submission_team,
       count(temp1.*) AS num_top_judge_votes_presentation
FROM (SELECT v_judge_team_total_score.judge_name,
             v_judge_team_total_score.submission_team,
             v_judge_team_total_score.presentation_score,
             rank()
             OVER (PARTITION BY v_judge_team_total_score.judge_name ORDER BY v_judge_team_total_score.presentation_score DESC) AS rank
      FROM v_judge_team_total_score) temp1
WHERE temp1.rank = 1
GROUP BY temp1.submission_team;

alter table v_top_teams_by_number_top_judge_votes_presentation owner to ccsandbox;

create or replace view v_top_teams_by_number_top_judge_votes_overall_general_xfactor(submission_team, num_top_judge_votes_overall_general_xfactor) as
SELECT temp1.submission_team,
       count(temp1.*) AS num_top_judge_votes_overall_general_xfactor
FROM (SELECT v_judge_team_total_score.judge_name,
             v_judge_team_total_score.submission_team,
             v_judge_team_total_score.overall_score,
             rank()
             OVER (PARTITION BY v_judge_team_total_score.judge_name ORDER BY v_judge_team_total_score.overall_score DESC) AS rank
      FROM v_judge_team_total_score) temp1
WHERE temp1.rank = 1
GROUP BY temp1.submission_team;

alter table v_top_teams_by_number_top_judge_votes_overall_general_xfactor owner to ccsandbox;

create or replace view v_top_teams_by_number_top_judge_votes_useability(submission_team, num_top_judge_votes_useability) as
SELECT temp1.submission_team,
       count(temp1.*) AS num_top_judge_votes_useability
FROM (SELECT v_judge_team_total_score.judge_name,
             v_judge_team_total_score.submission_team,
             v_judge_team_total_score.useability_score,
             rank()
             OVER (PARTITION BY v_judge_team_total_score.judge_name ORDER BY v_judge_team_total_score.useability_score DESC) AS rank
      FROM v_judge_team_total_score) temp1
WHERE temp1.rank = 1
GROUP BY temp1.submission_team;

alter table v_top_teams_by_number_top_judge_votes_useability owner to ccsandbox;

