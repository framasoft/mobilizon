from weasyprint import HTML

def generate(html):
    return HTML(string=html.decode('utf-8')).write_pdf()