from pyexcel_ods3 import save_data
from collections import OrderedDict
from io import BytesIO as StringIO
import json

def generate(data):
    struct = json.loads(data)
    data = OrderedDict()
    data.update({"Sheet 1": struct})
    io = StringIO()
    save_data(io, data)
    return io.getvalue()
