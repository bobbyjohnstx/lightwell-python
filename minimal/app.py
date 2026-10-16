import PyPDF2
import sqlparse


def main():
    print("Lightwell Python Demo — Minimal Script")
    print("=" * 45)

    sql = "SELECT name, email FROM customers WHERE status='active' ORDER BY name;"
    formatted = sqlparse.format(sql, reindent=True, keyword_case="upper")
    print(f"SQL parsing (sqlparse {sqlparse.__version__}):")
    print(formatted)
    print()

    print(f"PDF library loaded (PyPDF2 {PyPDF2.__version__})")
    print()
    print("These libraries have known CVEs at their current versions.")
    print("Run 'make scan' to check for vulnerabilities.")


if __name__ == "__main__":
    main()
