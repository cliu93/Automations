import re
import xlsxwriter
from datetime import datetime

# Open the output file generated by Ansible
today = datetime.today().strftime('%Y%m%d')
ansibleOutputFile = "MelDataCenterHardwareUsageReport." + today + ".output"
f = open(ansibleOutputFile, "r")

# Find the valid data we need to use, format the data to list, the list data will be used later
for i in f.readlines():
    if re.search(r'^\s+"mysql.*"', i):
        synologyMysql = i.strip().strip('\"').split()
        synologyMysql[4], synologyMysql[6] = synologyMysql[6], synologyMysql[4]
    elif re.search(r'^\s+"data_archives.*"', i):
        synologyArchive = i.strip().strip('\"').split()
        synologyArchive[4], synologyArchive[6] = synologyArchive[6], synologyArchive[4]
    elif re.search(r'^\s+".*LocalDiskA"', i):
        vspherehost01LocalDisk = i.strip().strip('\"').split()
    elif re.search(r'^\s+".*LocalDiskB"', i):
        vspherehost02LocalDisk = i.strip().strip('\"').split()
    elif re.search(r'^\s+".*LocalDiskC"', i):
        vspherehost03LocalDisk = i.strip().strip('\"').split()
    elif re.search(r'^\s+".*VM_SNAPSHOTS"', i):
        synologySnapshot = i.strip().strip('\"').split()
    elif re.search(r'^\s+".*ARCHIVES_VDISK"', i):
        DellSanArchive = i.strip().strip('\"').split()
    elif re.search(r'^\s+".*DB_VDISK"', i):
        DellSanDB = i.strip().strip('\"').split()
    elif re.search(r'^\s+".*PROD_VDISK"', i):
        DellSanProd = i.strip().strip('\"').split()
    elif re.search(r'^\s+".*INTDEVTESTUAT_VDISK"', i):
        DellSanIntDevTestUat = i.strip().strip('\"').split()
f.close()


# Define the function to display the CPU and Memory usage information
def findstrtolist(strs):
    ansibleOutputFile = "MelDataCenterCpuMemory." + today + ".output"
    f = open(ansibleOutputFile, "r")
    my_regex = r'^' + re.escape(strs) + r'.*'
    for i in f.readlines():
        if re.search(my_regex, i):
            result_tmp = i.split()
            result = [result_tmp[0], int(result_tmp[5]), int(result_tmp[4]), int(result_tmp[5]) - int(result_tmp[4]),
                      round(float(result_tmp[7].replace(",", ".")), 2),
                      round(float(result_tmp[6].replace(",", ".")), 2),
                      round((float(result_tmp[7].replace(",", ".")) - float(result_tmp[6].replace(",", "."))), 2)]
    f.close()
    return result


# Extract the vsphere CPU and memory usage
vsphere01Info = findstrtolist("vsphere01.example.com")
vsphere02Info = findstrtolist("vsphere02.example.com")
vsphere03Info = findstrtolist("vsphere03.example.com")
print(vsphere01Info)
print(vsphere02Info)
print(vsphere03Info)

'''
['vsphere01.example.com', 87960, 32241, 55719, 255.91, 206.54, 49.36]
['vsphere02.example.com', 87960, 12026, 75934, 255.91, 208.16, 47.75]
['vsphere03.example.com', 87960, 13305, 74655, 255.91, 213.5, 42.41]
'''

# Define function to convert disk size to Gb
def convertSizetoGb(str):
    if re.match(r'^\d+\.?\d*T$', str):
        s = float(str[:-1]) * 1024
    elif re.match(r'^\d+\.?\d*G$', str):
        s = float(str[:-1])
    elif re.match(r'^\d+\.?\d*M$', str):
        s = float(str[:-1]) / 1024
    elif re.match(r'.+%$', str):
        s = str
    return s


# Create an excel
workbook = xlsxwriter.Workbook("MelDataCenterHardwareUsageReport." + today + ".xlsx")

# Create a sheet
worksheet = workbook.add_worksheet()

# Define a format bold 1
bold = workbook.add_format({'bold': 1})

# Define the sheet heading
headings = ['Description', 'Total CPU GHz', 'Used CPU GHz', 'Free CPU GHz', 'Total Memory GB', 'Used Memory GB',
            'Free Memory GB', 'Disk Name', 'Total Usable Storage(GB)', 'Currently Used Storage(GB)', 'Free Storage(GB)',
            'Used(%)']

# Set Heading format
head_format = workbook.add_format()
head_format.set_border(1)
head_format.set_border_color('#B2B2B2')
head_format.set_bg_color('#FFFFCC')
head_format.set_bold()

# Write data
worksheet.write_row('A1', headings, head_format)
worksheet.write('H2', "LocalDiskA")
worksheet.write('H3', 'LocalDiskB')
worksheet.write('H4', 'LocalDiskC')
worksheet.write('H5', 'DB DISK')
worksheet.write('H6', 'PROD DISK')
worksheet.write('H7', 'INTDEVTESTUAT DISK')
worksheet.write('H8', 'ARCHIVE DISK')
worksheet.write('H9', 'ARCHIVE DISK')
worksheet.write('H10', 'SNAPSHOT/File DISK')
worksheet.write('H11', 'MYSQL DISK')

worksheet.write('A2', "vsphere01host")
worksheet.write('A3', 'vsphere02host')
worksheet.write('A4', 'vsphere03host')
worksheet.write('A5', 'DELL SAN')
worksheet.write('A6', 'DELL SAN')
worksheet.write('A7', 'DELL SAN')
worksheet.write('A8', 'DELL SAN')
worksheet.write('A9',  'SYNOLOGY')
worksheet.write('A10', 'SYNOLOGY')
worksheet.write('A11', 'SYNOLOGY')

for i in range(1, 7):
    worksheet.write(1, i, vsphere01Info[i])
    worksheet.write(2, i, vsphere02Info[i])
    worksheet.write(3, i, vsphere03Info[i])

for i in range(1, 5):
    worksheet.write(1, i+7, convertSizetoGb(vspherehost01LocalDisk[i]))
    worksheet.write(2, i+7, convertSizetoGb(vspherehost02LocalDisk[i]))
    worksheet.write(3, i+7, convertSizetoGb(vspherehost03LocalDisk[i]))
    worksheet.write(4, i+7, convertSizetoGb(DellSanDB[i]))
    worksheet.write(5, i+7, convertSizetoGb(DellSanProd[i]))
    worksheet.write(5, i+7, convertSizetoGb(DellSanProd[i]))
    worksheet.write(6, i+7, convertSizetoGb(DellSanIntDevTestUat[i]))
    worksheet.write(6, i+7, convertSizetoGb(DellSanIntDevTestUat[i]))
    worksheet.write(7, i+7, convertSizetoGb(DellSanArchive[i]))
    worksheet.write(8, i+7, convertSizetoGb(synologyArchive[i]))
    worksheet.write(9, i+7, convertSizetoGb(synologySnapshot[i]))
    worksheet.write(10, i+7, convertSizetoGb(synologyMysql[i]))

# Create a column chart
chart_col = workbook.add_chart({'type': 'column', 'subtype': 'percent_stacked'})

# Add chart series 1
chart_col.add_series(
    {
        'name': '=Sheet1!$J$1',
        'categories': '=Sheet1!$H$2:$H$11',
        'values': '=Sheet1!$J$2:$J$11',
        'fill': {'color': 'red'},
    }
)

# Add chart series 2
chart_col.add_series(
    {
        'name': '=Sheet1!$K$1',
        'categories': '=Sheet1!$H$2:$H$11',
        'values': '=Sheet1!$K$2:$K$11',
        'fill': {'color': 'green'},
    }
)

# Set chart properties and format
chart_col.set_title({'name': 'Mel DC Hardware Resource Report'})
chart_col.set_y_axis({'name': 'Usage %', 'name_font': {'size': 14, 'bold': True}}, )
chart_col.set_size({
    'x_scale': 3,
    'y_scale': 1.8
})

# Set Cell format
cell_format = workbook.add_format()
cell_format.set_border(1)
cell_format.set_border_color('#B2B2B2')
cell_format.set_bg_color('#FFFFCC')
worksheet.set_column('A:L', None, cell_format)

worksheet.conditional_format('B5:H11', {
    'type': 'cell',
    'criteria': '!=',
    'value': -10000,
    'format': cell_format
})

# Set column width
worksheet.set_column(0, 0, 13)
worksheet.set_column(1, 5, 16)
worksheet.set_column(6, 6, 20)
worksheet.set_column(7, 9, 26)
worksheet.set_column(10, 10, 8)

# Insert the chart
worksheet.insert_chart('A13', chart_col, {'x_offset': 25, 'y_offset': 10})

# Save and close
workbook.close()
