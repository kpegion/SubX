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
ax1.set_title('Anomaly correlation')
ax1.set_xticks(np.arange(5, 50, 5))
ax1.set_xlabel('Lead Time (Days)')

# RMSE plot
ax2.plot(np.arange(1, 46), np.full((45), 1.4), 'gray', linewidth=0.5)
ax2.set_yticks(np.arange(0, 2.2, 0.2))
ax2.set_title('RMSE')

plt.suptitle('SubX NAO Skill [Dec-Feb ICs]')


# Loop over models
models = ['30LCESM1', '46LCESM1', 'CCSM4', 'FIMr1p1', 'GEFS', 'GEM',
          'GEOS_V2p1', 'NESM', 'MME']
for i, model in enumerate(models):
    # Read in model data
    da = xr.open_dataarray(ddir+model+fdir+fname)
    fct = da.loc[da['S.season']=='DJF']
    # Read in observations
    da = xr.open_dataarray(obsdir+obsfname+model+'.nc')
    obs = da.loc[da['S.season']=='DJF']
    
    r = xs.pearson_r(obs, fct, 'S')
    _x = np.arange(1, len(da.L)+1)
    ax1.plot(_x, r.values, label=model)
    
    rmse = xs.rmse(obs, fct, 'S')
    ax2.plot(_x, rmse.values)
ax1.legend(loc="upper right")

plt.savefig(fsavename + '.png', bbox_inches = 'tight')
plt.savefig(fsavename + '.eps', bbox_inches = 'tight', format = 'eps')
plt.close()
