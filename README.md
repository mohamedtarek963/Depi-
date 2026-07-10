# Depi-
# E-Learning Analysis Project 🎓

An end-to-end data analytics project focused on student learning behavior, academic outcomes, and engagement platforms.

## 👥 Project Team
* Mohamed Tarek Ahmed
* Ahmed Sdeek Kamel
* Basmala Ehab Abd El-lateef
* Abdallah Ashraf Abdalla
* Nour yehia Zakaria
* Abdulrahman Ahmed Ibrahim

---

## 📝 Project Executive Summary
This project delivers a comprehensive analysis of student learning analytics data. It evaluates student enrollment outcomes, assessment scores, and Virtual Learning Environment (VLE) engagement (clicks), segmented by demographic characteristics and academic profiles. 

The analysis is based on the **Open University Learning Analytics Dataset (OULAD)** schema.

---

## 🏗️ Technical Architecture & Data Stack
The project spans across multiple technologies to store, process, and visualize the data:

1. **Data Warehouse (SQL Server):** 
   * Centralized relational database hosting the processed tables.
   * Structured using a classic **Star Schema** with optimized Fact and Dimension tables to serve analytics tools smoothly.
2. **Advanced Analytics (Python):** 
   * Used for exploratory data analysis (EDA), data cleaning, statistical evaluation, and finding deeper correlations between engagement and performance.
3. **Primary BI Tool (Power BI):** 
   * The core deliverable featuring interactive dashboards, comprehensive DAX measures, and highly customized visual reporting styles.
4. **Alternative Visualizations (Tableau & Excel):** 
   * **Tableau:** Supplementary interactive dashboards exploring specific cohort behaviors.
   * **Excel:** Ad-hoc reporting, quick pivot summaries, and baseline data verification.

---

## 🎯 Project Objectives
* Provide academic stakeholders (course leaders, student-success staff, and analysts) with a 360-degree view of student behavior.
* Identify demographic or academic segments that are highly at risk of failing or withdrawing.
* Quantify how digital engagement (VLE interaction frequencies) impacts final scores and retention rates.

---

## 🗄️ Data Warehouse Schema (SQL Server / Star Schema)
The underlying warehouse model centers around 3 central Fact tables and 4 major Dimension tables:

| Table Name | Type | Description / Grain |
| :--- | :--- | :--- |
| **Fact_Enrollment** | Fact | One row per student per module enrollment (stores final results). |
| **Fact_Student_Scores** | Fact | One row per student per assessment submission. |
| **Fact_Student_Vle_Clicks** | Fact | One row per student per week of VLE click activities. |
| **Dim_Students_Profile** | Dimension | Demographics: gender, region, age band, education, economic level, etc. |
| **Dim_Modules_Catalog** | Dimension | Contains details on courses/module presentations and semesters. |
| **Dim_Assessments_Info** | Dimension | Assessment information categorized by types (TMA, CMA, Exams). |
| **Dim_Vle_Resources** | Dimension | Holds specific definitions for VLE resource/activity types. |

---

## 📊 Core BI Implementation: Power BI Dashboard (Featured)
The Power BI report is structured as the ultimate presentation-ready solution using the custom `CY26SU02` visual theme.

### Key Analytical DAX Measures Built-In:
* **Overview & Aggregates:** `Total Students`, `Total Modules`, `Total Assessments`.
* **Engagement Insights:** `Total VLE Clicks`, `Avg Clicks per Student`.
* **Academic Performance:** `Avg Score by Result`, `Pass Rate %`, `Fail Rate %`, `Withdrawal Rate %`.
* **Behavior Tracking:** `On-Time Submission Rate %`, `Late Submission Rate %`.

### Dashboard Pages Structure:
* 🌐 **Dashboard 1 & 1 (Styled):** Dedicated to student demographic breakdowns, geographic distribution, and socio-economic status slicing.
* 📈 **Dashboard 2 & 2 (Styled):** Deep dive into performance trends, weekly student engagement timelines, and success rate correlations.
* 📋 **Dashboard 3 (Detail View):** Row-level tabular drill-downs for operational analysis.
* 📑 **Page 1 (Executive Summary):** A high-level overview canvas combining crucial KPIs from all dashboards into a 16:9 format.

---

## 📖 User & Navigation Guide
For the best evaluation experience of the dashboards:
1. **Understand Cohorts:** Start with the *Demographics page* to review the student base structure.
2. **Evaluate Behaviors:** Navigate to the *Performance & Engagement dashboards* to observe how active vs. inactive students perform.
3. **Drill Down:** Find specific edge cases or anomalies using the cross-filtering charts or by jumping into the *Detail Table view*.

*Note: Slicers are global/synced where applicable, allowing you to filter the data by gender, region, or credit loads across the sheets.*

---

## 📁 Technical Project Files Referenced
* **Main Report Source File:** `Analysis_FP_Project_Documentation.pdf` (Consult for detailed report-visual design mappings and architecture blueprints).
