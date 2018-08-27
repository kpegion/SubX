import numpy as np
import matplotlib.pyplot as plt
import xarray as xr
import xskillscore as xs
import os


# Setup directories and files
ddir = '/place/with/lots/of/storage/SubX/hindcast/'
fdir = '/zg/500/daily/NAO/point_based/'
fname = 'emean.1999-01-07.2014-12-28.np.y65.x304.sp.y42.x322.nc'
obsdir = '/place/with/lots/of/storage/ERA-Interim/zg/500/daily/SubX/'\
'NAO/point_based/'
obsfname = '1999-01-07.2014-12-28.np.y65.x304.sp.y42.x322.SubX.'
figdir = '/place/to/store/figs/'
if not os.path.isdir(figdir):
    os.makedirs(figdir)
fsavename = figdir+'SubX_NAO_skill'

# Setup plot
fig, (ax1, ax2) = plt.subplots(1, 2, sharex=True)
fig.set_size_inches(23.5, 8.5)

# Correlation plot
ax1.plot(np.arange(1, 46), np.full((45), 0.5), 'gray', linewidth=0.5)
ax1.set_yticks(np.arange(0, 1.1, 0.1))
ax1.set_title('Anomaly correlation', fontsize=16)
ax1.set_xticks(np.arange(5, 50, 5))
ax1.set_xlabel('Lead Time (Days)', fontsize=16)
ax1.tick_params(axis='both', which='major', labelsize=16)
ax1.tick_params(axis='both', which='minor', labelsize=16)

# RMSE plot
ax2.plot(np.arange(1, 46), np.full((45), 1.4), 'gray', linewidth=0.5)
ax2.set_yticks(np.arange(0, 2.2, 0.2))
ax2.set_title('RMSE', fontsize=16)
ax2.tick_params(axis='both', which='major', labelsize=16)
ax2.tick_params(axis='both', which='minor', labelsize=16)

plt.suptitle('SubX NAO Skill [Dec-Feb ICs]', fontsize=16)

# Loop over models
models = ['CCSM4', 'FIMr1p1', 'GEFS', 'GEM', 'GEOS_V2p1', 'NESM']
for i, model in enumerate(models):
    # Read in model data
    da = xr.open_dataarray(ddir+model+fdir+fname)
    fct = da.loc[da['S.season']=='DJF']
    # Read in observations
    da = xr.open_dataarray(obsdir+obsfname+model+'.nc')
    obs = da.loc[da['S.season']=='DJF']
    
    # Rename some models
    _model = model
    if _model == 'CCSM4':
        _line_color = 'black'       
    if _model == 'FIMr1p1':
        _model = 'FIM'
        _line_color = 'red'
    if _model == 'GEFS':
        _line_color = 'green'
    if _model == 'GEM':
        _line_color = 'blue'
    if _model == 'GEM':
        _line_color = 'blue'
    if _model == 'GEOS_V2p1':
        _model = 'GEOS'
        _line_color = 'purple'
    if _model == 'NESM':
        _line_color = 'orange'        
    
    r = xs.pearson_r(obs, fct, 'S')
    _r = r.values
    rmse = xs.rmse(obs, fct, 'S')
    _rmse = rmse.values
    
    _x = np.arange(1, len(da.L)+1)
        
    ax1.plot(_x, _r, label=_model, linewidth=2, color=_line_color)
    
    ax2.plot(_x, _rmse, linewidth=2, color=_line_color)
    
ax1.legend(loc="upper right", fontsize=16)

plt.savefig(fsavename + '.png', bbox_inches = 'tight')
plt.savefig(fsavename + '.eps', bbox_inches = 'tight', format = 'eps')
plt.close()
